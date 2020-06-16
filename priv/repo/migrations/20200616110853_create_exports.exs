defmodule AcariServer.Repo.Migrations.CreateExports do
  use Ecto.Migration

  def change do
    create table(:exports) do
      add :name, :string
      add :profile, :map
      add :common, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:exports, [:user_id])
  end
end
