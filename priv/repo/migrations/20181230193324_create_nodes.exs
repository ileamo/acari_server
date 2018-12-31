defmodule AcariServer.Repo.Migrations.CreateNodes do
  use Ecto.Migration

  def change do
    create table(:nodes) do
      add :sn, :string
      add :name, :string
      add :description, :string
      add :params, :map

      timestamps()
    end

    create unique_index(:nodes, [:sn])
    create unique_index(:nodes, [:name])
  end
end
