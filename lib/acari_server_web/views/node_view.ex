defmodule AcariServerWeb.NodeView do
  use AcariServerWeb, :view

  def groups_list(node) do
    node.groups
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(",")
  end
end
