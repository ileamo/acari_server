defmodule AcariServer.Repo.Migrations.CreateFilrers do
  use Ecto.Migration

  def change do
    create table(:filrers) do
      add :description, :string
      add :filter, :text
      add :common, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:filrers, [:user_id])
  end
end
