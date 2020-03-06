defmodule AcariServerWeb.TunnelController do
  use AcariServerWeb, :controller
  alias AcariServer.GroupManager
  alias AcariServer.NodeManager

  import AcariServer.UserManager, only: [is_user_in_group: 2]
  plug :is_user_in_group when action in [:show, :grp]

  def index(%{assigns: %{current_user: %{is_admin: true}}} = conn, _params) do
    nodes = NodeManager.list_nodes_wo_preload()
    render(conn, "index.html", nodes: nodes, group_id: nil, group_name: "Все")
  end

  def index(%{assigns: %{current_user: user}} = conn, _params) do
    groups =
      user
      |> AcariServer.RepoRO.preload(groups: :nodes)
      |> Map.get(:groups)

    nodes =
      groups
      |> Enum.map(fn %{nodes: nodes} -> nodes end)
      |> List.flatten()
      |> Enum.uniq_by(fn %{id: id} -> id end)

    render(conn, "index.html", nodes: nodes, group_id: nil, group_name: "Все", groups: groups)
  end

  def grp(%{assigns: %{current_user: user = %{is_admin: admin}}} = conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)

    render(conn, "index.html",
      nodes: group.nodes,
      group_id: group.id,
      group_name: group.name,
      groups:
        case admin do
          true ->
            nil

          _ ->
            user
            |> AcariServer.RepoRO.preload(:groups)
            |> Map.get(:groups)
        end
    )
  end

  def show(conn, %{"name" => name}) do
    node = AcariServer.NodeManager.get_node_with_class(name)
    render(conn, "show.html", name: name, node: node)
  end
end
