defmodule AcariServer.Repo do
  use Ecto.Repo,
    otp_app: :acari_server,
    adapter: Ecto.Adapters.Postgres

  @params [
    username: "postgres",
    password: "postgres",
    database: "acari_server_prod",
    pool_size: 10
  ]
  def init(:runtime, config) do
    {:ok, config |> Keyword.merge(@params)}
  end

  def init(_type, config) do
    host_port = AcariServer.RepoManager.get_db_config(:rw)
    {:ok, config |> Keyword.merge(@params) |> Keyword.merge(host_port)}
  end
end
