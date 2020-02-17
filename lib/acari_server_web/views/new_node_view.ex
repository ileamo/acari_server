defmodule AcariServerWeb.NewNodeView do
  use AcariServerWeb, :view
  defdelegate group_name_id_pairs_list(), to: AcariServer.GroupManager
  defdelegate script_name_id_pairs_list(), to: AcariServerWeb.NodeView
end
