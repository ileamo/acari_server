defmodule AcariServerWeb.NodeView do
  use AcariServerWeb, :view
  @no_script "<NO_CLASS>"

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

  def redirect_path(conn) do
    NavigationHistory.last_paths(conn)
    |> Enum.find(fn x -> String.match?(x, ~r{/nodes/grp/\d+}) end) ||
      Routes.node_path(conn, :index)
  end
end
