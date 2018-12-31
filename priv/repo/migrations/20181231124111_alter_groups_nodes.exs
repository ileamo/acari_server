defmodule AcariServer.Repo.Migrations.AlterGroupsNodes do
  use Ecto.Migration

  def change do
    alter table(:groups_nodes) do
      add :group_id, references(:groups, on_delete: :nothing)
      add :node_id, references(:nodes, on_delete: :nothing)
    end
  end
end
