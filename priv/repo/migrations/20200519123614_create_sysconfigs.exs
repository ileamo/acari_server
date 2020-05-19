defmodule AcariServer.Repo.Migrations.CreateSysconfigs do
  use Ecto.Migration

  def change do
    create table(:sysconfigs) do
      add :name, :string
      add :value, :text

      timestamps()
    end

  end
end
