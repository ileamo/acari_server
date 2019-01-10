defmodule AcariServer.Repo.Migrations.CreateNewnodes do
  use Ecto.Migration

  def change do
    create table(:newnodes) do
      add :name, :string
      add :ip_addr, :string
      add :template, :string
      add :params, :map

      timestamps()
    end

    create unique_index(:newnodes, [:name])
  end
end
