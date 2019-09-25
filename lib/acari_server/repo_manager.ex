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
    IO.inspect("START RepoManager")
    Process.flag(:trap_exit, true)
    Process.send_after(self(), {:connect_db, :rw}, 1_000)
    Process.send_after(self(), {:connect_db, :ro}, 1_000)
    {:ok, %State{}}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %State{rw: %{pid: pid}} = state) do
    db_down(:rw, reason, state)
  end

  def handle_info({:EXIT, pid, reason}, %State{ro: %{pid: pid}} = state) do
    db_down(:ro, reason, state)
  end

  def handle_info({:connect_db, repo_type}, state) do
    {:noreply, state |> Map.put(repo_type, notifications_start_link(repo_type))}
  end

  def handle_info(_message, state) do
    # IO.inspect(message)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp db_down(repo_type, reason, state) do
    config = Map.get(state, repo_type).config

    Logger.error(
      "DB #{config[:hostname]}:#{config[:port]} down: #{
        reason |> Map.get(:message) || inspect(reason)
      }"
    )

    Process.send_after(self(), {:connect_db, repo_type}, 10_000)
    {:noreply, state |> Map.put(repo_type, %{pid: nil})}
  end

  defp notifications_start_link(repo_type) do
    repo_config =
      case repo_type do
        :rw -> AcariServer.Repo.config()
        :ro -> AcariServer.RepoRO.config()
      end

    case Postgrex.Notifications.start_link(repo_config) do
      {:ok, pid} ->
        %{pid: pid, config: repo_config}

      {:error, reason} ->
        Logger.error(
          "DB #{repo_config[:hostname]}:#{repo_config[:port]} connect error: #{
            reason |> Map.get(:message) || inspect(reason)
          }"
        )

        Process.send_after(self(), {:connect_db, repo_type}, 10_000)
        %{pid: nil}
    end
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def get_state(node) do
    GenServer.call({__MODULE__, node}, :get_state)
  end

  def pg_is_in_recovery(repo) do
    case SQL.query(repo, "select pg_is_in_recovery();", []) do
      {:ok, %Postgrex.Result{rows: [[res]]}} -> res
      _ -> nil
    end
  end
end
