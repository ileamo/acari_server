defmodule AcariServer.RepoRO do
  use Ecto.Repo,
    otp_app: :acari_server,
    adapter: Ecto.Adapters.Postgres,
    read_only: true

  @params [
    username: "postgres",
    password: "postgres",
    database: "bogatka",
    pool_size: 10,
    telemetry_prefix: [:bogatka, :bd_ro]

  ]

  def init(:runtime, config) do
    {:ok, config |> Keyword.merge(@params)}
  end

  def init(_type, config) do
    host_port = AcariServer.RepoManager.get_db_config(:ro)
    {:ok, config |> Keyword.merge(@params) |> Keyword.merge(host_port)}
  end

  def get_wait(schema, id) do
    [0, 100, 200, 400, 800]
    |> Enum.find_value(fn delay ->
      Process.sleep(delay)
      get(schema, id)
    end)
  end
end
