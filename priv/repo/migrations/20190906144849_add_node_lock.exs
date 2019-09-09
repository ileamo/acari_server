defmodule AcariServer.Repo.Migrations.AddNodeLock do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add(:lock, :boolean, default: false, null: false)
    end

  end
end
