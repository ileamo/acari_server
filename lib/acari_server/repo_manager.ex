defmodule AcariServer.RepoManager do
  use GenServer
  alias Ecto.Adapters.SQL

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  @impl true
  def init(_params) do
    IO.inspect("START RepoManager")
    Process.flag(:trap_exit, true)

    case Postgrex.Notifications.start_link(
           username: "postgres",
           password: "postgres",
           database: "acari_server_prod",
           hostname: "10.0.10.10",
           port: 51432,
           pool_size: 10
         ) do
      {:ok, _pid} -> :ok
      err -> IO.inspect(err)
    end

    {:ok, %{}}
  end

  def handle_info(message, state) do
    IO.inspect(message)
    {:noreply, state}
  end

  def pg_is_in_recovery(repo) do
    case SQL.query(repo, "select pg_is_in_recovery();", []) do
      {:ok, %Postgrex.Result{rows: [[res]]}} -> res
      _ -> nil
    end
  end
end
