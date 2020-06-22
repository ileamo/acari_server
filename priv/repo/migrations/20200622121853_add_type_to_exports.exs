defmodule AcariServer.Repo.Migrations.AddTypeToExports do
  use Ecto.Migration

  def change do
    alter table(:exports) do
      add(:type, :string, default: "")
    end
  end
end
