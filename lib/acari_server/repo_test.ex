defmodule AcariServer.RepoTest do
  use Ecto.Repo,
    otp_app: :acari_server,
    adapter: Ecto.Adapters.Postgres
end
