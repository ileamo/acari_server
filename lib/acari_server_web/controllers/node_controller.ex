defmodule AcariServerWeb.NodeController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.NodeManager
  alias AcariServer.NodeManager.Node
  alias AcariServer.RepoRO
  alias AcariServer.Repo

  import AcariServer.UserManager,
    only: [is_admin: 2, is_user_node_rw: 2, is_user_node_ro: 2, is_user_in_group: 2]

  plug :is_admin when action in [:new, :exec_selected]
  plug :is_user_node_rw, :node when action in [:edit, :delete]
  plug :is_user_node_ro, :node when action in [:show]
  plug :is_user_in_group when action in [:client_grp]

  def index(%{assigns: %{current_user: %{is_admin: true}}} = conn, _params) do
    nodes = NodeManager.list_nodes()
    render(conn, "index.html", nodes: nodes)
  end

  def index(%{assigns: %{current_user: user}} = conn, _params) do
    nodes =
      user
      |> AcariServer.RepoRO.preload(groups: :nodes)
      |> Map.get(:groups)
      |> Enum.map(fn %{nodes: nodes} -> nodes end)
      |> List.flatten()
      |> Enum.uniq_by(fn %{id: id} -> id end)
      |> RepoRO.preload([:groups, :script])

    render(conn, "index.html", nodes: nodes)
  end

  def client_grp(conn, %{"id" => group_id}) do
    nodes =
      AcariServer.GroupManager.get_group!(group_id)
      |> Map.get(:nodes)
      |> RepoRO.preload([:script, :groups])

    render(conn, "index.html", nodes: nodes)
  end

  def new(conn, %{"node_id" => id}) do
    node = NodeManager.get_node!(id)

    changeset = NodeManager.change_node(node |> Ecto.put_meta(state: :built))

    render(conn, "new.html", changeset: changeset, node: node)
  end

  def new(conn, params) do
    changeset =
      NodeManager.change_node(%Node{
        name: params["id"],
        latitude: params["latitude"],
        longitude: params["longitude"]
      })

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"node" => node_params} = attrs) do
    node_params = Map.put(node_params, "params", attrs["params"] || %{})

    case NodeManager.create_node(node_params) do
      {:ok, node} ->
        conn
        |> put_flash(:info, "Клиент создан.")
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

    old_node = NodeManager.get_node!(id)

    case NodeManager.update_node(old_node, node_params) do
      {:ok, node} ->
        conn
        |> put_flash(:info, "Клиент отредактирован.")
        |> redirect(to: Routes.node_path(conn, :show, node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", node: old_node, changeset: changeset)
    end
  end

  defp delete_node_and_tunnel(id) do
    node = NodeManager.get_node!(id)
    {:ok, _node} = NodeManager.delete_node(node)
    AcariServer.Master.delete_tunnel(node.name)
  end

  def delete(conn, %{"id" => id}) do
    delete_node_and_tunnel(id)

    conn
    |> put_flash(:info, "Клиент удален.")
    |> redirect(to: Routes.node_path(conn, :index))
  end

  def toggle_lock(conn, %{"id" => id, "lock" => lock}) do
    node = NodeManager.get_node_rw!(id)
    node_params = %{"lock" => lock, "groups_list" => false}
    {:ok, node} = NodeManager.update_node(node, node_params)

    if node.lock do
      AcariServer.Master.delete_tunnel(node.name)
    end

    Process.sleep(1000)

    conn
    |> put_flash(:info, "Клиент #{node.name} #{if node.lock, do: "за", else: "раз"}блокирован.")
    |> redirect(to: Routes.node_path(conn, :index))
  end

  def exec_selected(conn, params = %{"clients_list" => ids, "operation" => operation}) do
    String.split(ids, ",")
    |> Enum.each(fn id ->
      case operation do
        "delete" ->
          delete_node_and_tunnel(id)

        "lock" ->
          node = NodeManager.get_node_rw!(id)
          {:ok, node} = NodeManager.update_node(node, %{"lock" => true, "groups_list" => false})
          AcariServer.Master.delete_tunnel(node.name)

        "unlock" ->
          NodeManager.get_node_rw!(id)
          |> NodeManager.update_node(%{"lock" => false, "groups_list" => false})

        "class" ->
          NodeManager.get_node_rw!(id)
          |> NodeManager.update_node(%{"script_id" => params["script_id"], "groups_list" => false})

        "groups" ->
          NodeManager.get_node_rw!(id)
          |> Repo.preload(:groups)
          |> NodeManager.update_node(%{"groups_list" => params["groups_list"]})

        op ->
          Logger.error("Bad mass-operation: #{op}")
      end
    end)

    conn
    |> redirect(to: Routes.node_path(conn, :index))
  end
end
