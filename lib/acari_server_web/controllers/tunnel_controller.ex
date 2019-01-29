defmodule AcariServerWeb.TunnelController do
  use AcariServerWeb, :controller
  alias AcariServer.GroupManager
  alias AcariServer.NodeManager

  def index(conn, _params) do
    nodes = NodeManager.list_nodes_wo_preload()
    render(conn, "index.html", nodes: nodes, group_id: nil, group_name: "Все")
  end

  def grp(conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)
    render(conn, "index.html", nodes: group.nodes, group_id: group.id, group_name: group.name)
  end

  def show(conn, %{"name" => name}) do
    render(conn, "show.html", name: name)
  end
end
