defmodule AcariServer.Release do
  alias AcariServer.Repo
  alias AcariServer.UserManager.User

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  def migrate do
    Application.load(:acari_server)

    {:ok, migrated, _} =
      Ecto.Migrator.with_repo(AcariServer.Repo, &Ecto.Migrator.run(&1, :up, all: true))

    case migrated do
      [] -> IO.puts("Already up")
      list -> list |> Enum.each(fn id -> IO.puts("Migrated #{id}") end)
    end
  end

  def rollback(version) do
    {:ok, _, _} =
      Ecto.Migrator.with_repo(AcariServer.Repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed() do
    Application.load(:acari_server)
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    AcariServer.Repo.start_link()

    admin_params = %{
      username: "admin",
      password: "admin",
      rpt_psw: "admin",
      is_admin: true
    }

    unless Repo.get_by(User, username: admin_params[:username]) do
      %User{}
      |> User.changeset(admin_params)
      |> Repo.insert!()
    else
      IO.puts("User 'admin' already exists")
    end
  end
end
