defmodule AcariServer.Repo.Migrations.AddApiToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:api, :boolean, default: false, null: false)
    end
  end
end
