defmodule AcariServerWeb.NodeController do
  use AcariServerWeb, :controller

  alias AcariServer.NodeManager
  alias AcariServer.NodeManager.Node

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new]

  def index(conn, _params) do
    nodes = NodeManager.list_nodes()
    render(conn, "index.html", nodes: nodes)
  end

  def new(conn, %{"node_id" => id}) do
    node = NodeManager.get_node!(id)

    changeset = NodeManager.change_node(node |> Ecto.put_meta(state: :built))

    render(conn, "new.html", changeset: changeset, node: node)
  end

  def new(conn, params) do
    changeset = NodeManager.change_node(%Node{name: params["name"]})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"node" => node_params}) do
    case NodeManager.create_node(node_params) do
      {:ok, node} ->
        AcariServer.NewNodeDiscovery.delete_new_node_by_name(node.name)

        if node.script_id == nil do
          conn
          |> put_flash(:info, "Клиент создан.")
          |> redirect(to: Routes.node_path(conn, :show, node))
        else
          conn
          |> put_flash(:error, "Изменен параметр Класс. Проверьте параметры.")
          |> edit(%{"id" => node.id})
        end

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

    old_node = NodeManager.get_node!(id)

    case NodeManager.update_node(old_node, node_params) do
      {:ok, node} ->
        if old_node.script_id == node.script_id or node.script_id == nil do
          conn
          |> put_flash(:info, "Клиент отредактирован.")
          |> redirect(to: Routes.node_path(conn, :show, node))
        else
          conn
          |> put_flash(:error, "Изменен параметр Класс. Проверьте параметры.")
          |> edit(%{"id" => node.id})
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", node: old_node, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    node = NodeManager.get_node!(id)
    {:ok, _node} = NodeManager.delete_node(node)
    AcariServer.Master.delete_tunnel(node.name)

    conn
    |> put_flash(:info, "Клиент удален.")
    |> redirect(to: Routes.node_path(conn, :index))
  end
end
