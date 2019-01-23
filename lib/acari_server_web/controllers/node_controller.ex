defmodule AcariServerWeb.NodeController do
  use AcariServerWeb, :controller

  alias AcariServer.NodeManager
  alias AcariServer.NodeManager.Node

  def index(conn, _params) do
    nodes = NodeManager.list_nodes()
    render(conn, "index.html", nodes: nodes)
  end

  def new(conn, params) do
    changeset = NodeManager.change_node(%Node{name: params["name"]})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"node" => node_params}) do
    case NodeManager.create_node(node_params) do
      {:ok, node} ->
        AcariServer.NewNodeDiscovery.delete_new_node_by_name(node.name)

        conn
        |> put_flash(:info, "Узел создан.")
        |> redirect(to: Routes.node_path(conn, :show, node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    node = NodeManager.get_node!(id)
    render(conn, "show.html", node: node)
  end

  def edit(conn, %{"id" => id}) do
    node = NodeManager.get_node!(id)
    changeset = NodeManager.change_node(node)
    render(conn, "edit.html", node: node, changeset: changeset)
  end

  def update(conn, %{"id" => id, "node" => node_params} = attrs) do
    node_params = Map.put(node_params, "params", attrs["params"] || %{})

    node = NodeManager.get_node!(id)

    case NodeManager.update_node(node, node_params) do
      {:ok, node} ->
        conn
        |> put_flash(:info, "Узел отредактирован.")
        |> redirect(to: Routes.node_path(conn, :show, node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", node: node, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    node = NodeManager.get_node!(id)
    {:ok, _node} = NodeManager.delete_node(node)

    conn
    |> put_flash(:info, "Узел удален.")
    |> redirect(to: Routes.node_path(conn, :index))
  end
end
