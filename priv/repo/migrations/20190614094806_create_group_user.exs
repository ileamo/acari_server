defmodule AcariServer.Repo.Migrations.CreateGroupUser do
  use Ecto.Migration

  def change do
    create table(:groups_users) do
      add(:group_id, references(:groups, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      timestamps()
    end

    create(unique_index(:groups_users, [:group_id, :user_id], name: :group_id_user_id_index))
  end
end
