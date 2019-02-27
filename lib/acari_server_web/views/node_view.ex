defmodule AcariServerWeb.NodeView do
  use AcariServerWeb, :view
  @no_script "<NO_CLASS>"

  def groups_list(node) do
    node.groups
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(", ")
  end

  def group_id_list(nil) do
    []
  end

  def group_id_list(node) do
    node.groups
    |> Enum.map(fn %{id: id} -> id end)
  end

  def script_name(node) do
    case node.script do
      nil -> @no_script
      scr -> scr.name
    end
  end

  defdelegate group_name_id_pairs_list(), to: AcariServer.GroupManager

  def script_name_id_pairs_list() do
    AcariServer.ScriptManager.script_name_id_pairs_list(@no_script)
  end

  def param_list(nil), do: ""

  def param_list(param_map) do
    param_map
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join(", ")
  end
end
