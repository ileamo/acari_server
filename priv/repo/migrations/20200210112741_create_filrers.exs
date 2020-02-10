defmodule AcariServer.Repo.Migrations.CreateFilrers do
  use Ecto.Migration

  def change do
    create table(:filrers) do
      add :description, :string
      add :filter, :text
      add :common, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:filrers, [:user_id])
  end
end
