defmodule AcariServer.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string
      add :description, :string

      timestamps()
    end

    create unique_index(:groups, [:name])
  end
end
