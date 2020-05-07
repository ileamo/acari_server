defmodule AcariServer.Repo do
  use Ecto.Repo,
    otp_app: :acari_server,
    adapter: Ecto.Adapters.Postgres

  @params [
    username: "postgres",
    password: "postgres",
    database: "bogatka",
    pool_size: 10,
    telemetry_prefix: [:bogatka, :bd_rw]
  ]
  def init(:runtime, config) do
    {:ok, config |> Keyword.merge(@params)}
  end

  def init(_type, config) do
    host_port = AcariServer.RepoManager.get_db_config(:rw)
    {:ok, config |> Keyword.merge(@params) |> Keyword.merge(host_port)}
  end

  def delete_wait(record) do
    res = delete(record)

    [0, 100, 200, 400, 800]
    |> Enum.find_value(fn delay ->
      Process.sleep(delay)
      !AcariServer.RepoRO.get(record.__struct__, record.id)
    end)

    res
  end
end
