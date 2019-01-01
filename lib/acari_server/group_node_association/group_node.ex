defmodule AcariServer.GroupNodeAssociation.GroupNode do
  use Ecto.Schema

  @primary_key false
  schema "groups_nodes" do
    belongs_to :group, AcariServer.GroupManager.Group
    belongs_to :node, AcariServer.NodeManager.Node

    timestamps()
  end

  def changeset(group_node, attrs \\ %{}) do
    group_node
    |> Ecto.Changeset.cast(attrs, [:group_id, :node_id])
    |> Ecto.Changeset.validate_required([:group_id, :node_id])
    |> Ecto.Changeset.foreign_key_constraint(:group_id)
    |> Ecto.Changeset.foreign_key_constraint(:node_id)
    |> Ecto.Changeset.unique_constraint(:group_id, name: :group_id_node_id_index)
  end
end
