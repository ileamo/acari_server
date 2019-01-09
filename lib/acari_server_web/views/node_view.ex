defmodule AcariServerWeb.NodeView do
  use AcariServerWeb, :view

  def groups_list(node) do
    node.groups
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(",")
  end

  def group_id_list(nil) do
    []
  end

  def group_id_list(node) do
    node.groups
    |> Enum.map(fn %{id: id} -> id end)
  end

  def group_name_id_pairs_list() do
    AcariServer.GroupManager.list_groups()
    |> Enum.map(fn %{name: name, id: id} -> {name, id} end)
    |> Enum.sort_by(&elem(&1, 0))
  end
end
