defmodule AcariServer.Repo do
  use Ecto.Repo,
    otp_app: :acari_server,
    adapter: Ecto.Adapters.Postgres

  def init(type, config) do
    params = [
      username: "postgres",
      password: "postgres",
      database: "acari_server_prod",
      pool_size: 10
    ]

    {:ok, config |> Keyword.merge(params)}
  end
end
