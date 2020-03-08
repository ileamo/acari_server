defmodule AcariServer.Repo.Migrations.AddUsersDescription do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :description, :string
    end
  end
end
