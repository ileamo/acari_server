defmodule AcariServer.GroupNodeAssociation do
  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.GroupNodeAssociation.GroupNode

  def create_group_node(attrs \\ %{}) do
    %GroupNode{}
    |> GroupNode.changeset(attrs)
    |> Repo.insert()
  end

  def get_node_list_for_group(group_id) do
    from(gn in GroupNode, where: gn.group_id == ^group_id)
    |> RepoRO.all()
    |> Enum.map(fn %{node_id: node_id} -> node_id end)
  end

  def get_group_list_for_node(node_id) do
    from(gn in GroupNode, where: gn.node_id == ^node_id)
    |> RepoRO.all()
    |> Enum.map(fn %{group_id: group_id} -> group_id end)
  end
end
