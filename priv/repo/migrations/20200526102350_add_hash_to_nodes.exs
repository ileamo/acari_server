defmodule AcariServer.Repo.Migrations.AddHashToNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add(:hash, :string)
    end
    create(index(:nodes, [:hash]))
  end
end
