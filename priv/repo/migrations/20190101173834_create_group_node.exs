defmodule AcariServer.Repo.Migrations.CreateGroupNode do
  use Ecto.Migration

  def change do
    create table(:groups_nodes) do
      add :group_id, references(:groups, on_delete: :delete_all)
      add :node_id, references(:nodes, on_delete: :delete_all)
      timestamps()
    end
    create unique_index(:groups_nodes, [:group_id, :node_id], name: :group_id_node_id_index)
  end
end
