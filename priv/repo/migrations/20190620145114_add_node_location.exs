defmodule AcariServer.Repo.Migrations.AddNodeLocation do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add(:latitude, :float)
      add(:longitude, :float)
    end
  end
end
