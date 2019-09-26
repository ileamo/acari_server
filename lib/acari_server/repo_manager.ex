defmodule AcariServer.RepoManager do
  use GenServer
  alias Ecto.Adapters.SQL
  require Logger

  defmodule State do
    defstruct rw: %{pid: nil},
              ro: %{pid: nil}
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    Process.flag(:trap_exit, true)

    conf = Application.get_env(:acari_server, AcariServer.RepoManager)

    rw_db_list = host_port_csv_to_repo_config(conf[:rw])
    ro_db_list = host_port_csv_to_repo_config(conf[:ro])

    {rw_pid, rw_host_port} = get_db_rw(rw_db_list)
    {ro_pid, ro_host_port} = get_db_ro(ro_db_list)

    {:ok,
     %State{
       rw: %{pid: rw_pid, config: rw_host_port, db_list: rw_db_list},
       ro: %{pid: ro_pid, config: ro_host_port, db_list: ro_db_list}
     }}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %State{rw: %{pid: pid}} = state) do
    db_down(:rw, reason, state)
  end

  def handle_info({:EXIT, pid, reason}, %State{ro: %{pid: pid}} = state) do
    db_down(:ro, reason, state)
  end

  def handle_info({:connect_db, :rw}, state) do
    {pid, host_port} = get_db_rw(state.rw[:db_list])

    case pid do
      pid when is_pid(pid) -> AcariServer.Repo.stop()
      _ -> Process.send_after(self(), {:connect_db, :rw}, 10_000)
    end

    {:noreply, %State{state | rw: state.rw |> Map.merge(%{pid: pid, config: host_port})}}
  end

  def handle_info({:connect_db, :ro}, state) do
    {pid, host_port} = get_db_ro(state.ro[:db_list])

    case pid do
      pid when is_pid(pid) -> AcariServer.RepoRO.stop()
      _ -> Process.send_after(self(), {:connect_db, :ro}, 10_000)
    end

    {:noreply, %State{state | ro: state.ro |> Map.merge(%{pid: pid, config: host_port})}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_db_conn, _from, state) do
    {:reply, state |> get_db_conn_p(), state}
  end

  def handle_call({:get_db_config, repo_type}, _from, state) do
    repo_params =
      state
      |> Map.get(repo_type)

    res =
      case repo_params[:config] do
        conf when is_list(conf) ->
          conf

        _ ->
          case repo_params[:db_list] do
            [conf | _] -> conf
            _ -> []
          end
      end

    {:reply, res, state}
  end

  defp db_down(repo_type, reason, state) do
    repo_state = Map.get(state, repo_type)
    config = repo_state.config

    Logger.error(
      "DB #{config[:hostname]}:#{config[:port]} down: #{
        reason |> Map.get(:message) || inspect(reason)
      }"
    )

    Process.send_after(self(), {:connect_db, repo_type}, 10_000)
    {:noreply, state |> Map.put(repo_type, repo_state |> Map.merge(%{pid: nil, config: nil}))}
  end

  defp get_db_ro(db_list) do
    db_list
    |> Enum.reduce_while({nil, nil}, fn host_port, acc ->
      case notifications_start_link(:ro, host_port) do
        {:ok, pid} -> {:halt, {pid, host_port}}
        _ -> {:cont, acc}
      end
    end)
  end

  defp get_db_rw(db_list) do
    db_list
    |> Enum.reduce_while({nil, nil}, fn host_port, acc ->
      case notifications_start_link(:rw, host_port) do
        {:ok, pid} ->
          case is_rw?(host_port) do
            true ->
              {:halt, {pid, host_port}}

            _ ->
              GenServer.stop(pid)
              {:cont, acc}
          end

        _ ->
          {:cont, acc}
      end
    end)
  end

  defp is_rw?(host_port) do
    case AcariServer.RepoTest.start_link(
           AcariServer.Repo.config()
           |> Keyword.merge(host_port)
           # |> Keyword.put(:name, nil)
         ) do
      {:ok, _repo} ->
        res = pg_is_in_recovery(AcariServer.RepoTest)

        AcariServer.RepoTest.stop()

        !res

      _ ->
        # AcariServer.RepoTest.stop(5000)
        false
    end
  end

  defp notifications_start_link(repo_type, host_port) do
    case repo_type do
      :rw -> AcariServer.Repo.config()
      :ro -> AcariServer.RepoRO.config()
    end
    |> Keyword.merge(host_port)
    |> Postgrex.Notifications.start_link()
  end

  defp get_db_conn_p(state) do
    state
    |> Map.from_struct()
    |> Enum.map(fn
      {k, %{config: c}} -> {k, "#{c[:hostname]}:#{c[:port]}"}
      {k, _} -> {k, nil}
    end)
  end

  defp host_port_csv_to_repo_config(csv) when is_binary(csv) do
    ~r|([^:,;\s]+):?([\d]*)|
    |> Regex.scan(csv)
    |> Enum.map(fn
      [_, host, ""] ->
        [hostname: host]

      [_, host, port] ->
        [hostname: host, port: port |> String.to_integer()]
    end)
  end

  defp host_port_csv_to_repo_config(_) do
    []
  end

  def get_db_conn() do
    GenServer.call(__MODULE__, :get_db_conn)
  end

  def get_db_conn(node) do
    GenServer.call({__MODULE__, node}, :get_db_conn)
  end

  def get_db_config(repo_type) do
    GenServer.call(__MODULE__, {:get_db_config, repo_type})
  end

  def pg_is_in_recovery(repo) do
    case SQL.query(repo, "select pg_is_in_recovery();", []) do
      {:ok, %Postgrex.Result{rows: [[res]]}} -> res
      _ -> true
    end
  end
end
