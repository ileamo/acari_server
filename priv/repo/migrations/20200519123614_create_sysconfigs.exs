defmodule AcariServer.Repo.Migrations.CreateSysconfigs do
  use Ecto.Migration

  def change do
    create table(:sysconfigs) do
      add :key, :string
      add :value, :text

      timestamps()
    end
    create(index(:sysconfigs, [:key]))

  end
end
