defmodule AcariServer.Repo.Migrations.ModifyFiltersUserId do
  use Ecto.Migration

  def change do
    alter table(:filrers) do
      remove(:user_id)
      add(:user_id, references(:users, on_delete: :delete_all))
    end
  end
end
