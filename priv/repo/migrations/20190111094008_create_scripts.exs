defmodule AcariServer.Repo.Migrations.CreateScripts do
  use Ecto.Migration

  def change do
    create table(:scripts) do
      add :name, :string
      add :local, :string
      add :remote, :string

      timestamps()
    end

    create unique_index(:scripts, [:name])
  end
end
