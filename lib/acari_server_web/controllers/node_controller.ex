defmodule AcariServerWeb.NodeController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.NodeManager
  alias AcariServer.NodeManager.Node
  alias AcariServer.RepoRO
  alias AcariServer.Repo
  alias AcariServer.ClientCommentManager
  alias AcariServer.AuditManager

  import AcariServer.UserManager,
    only: [is_admin: 2, is_user_node_rw: 2, is_user_node_ro: 2, is_user_in_group: 2]

  plug :is_admin when action in [:new, :exec_selected]
  plug :is_user_node_rw, :node when action in [:delete]
  plug :is_user_node_ro, :node when action in [:show]
  plug :is_user_in_group when action in [:client_grp]

  def index(%{assigns: %{current_user: %{is_admin: true}}} = conn, _params) do
    nodes =
      NodeManager.list_nodes()
      |> RepoRO.preload(client_comments: :user)

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
      |> RepoRO.preload([:groups, :script, client_comments: :user])

    render(conn, "index.html", nodes: nodes)
  end

  def client_grp(conn, %{"id" => group_id}) do
    group = AcariServer.GroupManager.get_group!(group_id)

    nodes =
      group
      |> Map.get(:nodes)
      |> RepoRO.preload([:script, :groups, client_comments: :user])

    render(conn, "index.html", nodes: nodes, group: group)
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
        |> AuditManager.create_audit_log(node, "create", node_params)
        |> put_flash(:info, "Клиент создан.")
        |> redirect(to: Routes.node_path(conn, :show, node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    node =
      NodeManager.get_node!(id)
      |> RepoRO.preload(client_comments: :user)

    render(conn, "show.html", node: node)
  end

  def edit(conn, %{"id" => id}) do
    conn =
      case AcariServer.SysConfigManager.get_conf_by_key("admin.ro_plus") do
        "on" -> conn
        _ -> is_user_node_rw(conn, :node)
      end

    case conn.halted do
      true ->
        conn

      _ ->
        node =
          NodeManager.get_node!(id)
          |> RepoRO.preload(client_comments: :user)

        changeset = NodeManager.change_node(node)
        render(conn, "edit.html", node: node, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "node" => node_params} = attrs) do
    node_params = Map.put(node_params, "params", attrs["params"] || %{})

    old_node = NodeManager.get_node!(id)

    case NodeManager.update_node(old_node, node_params, user: conn.assigns.current_user) do
      {:ok, node} ->
        Process.sleep(1000)

        conn
        |> AuditManager.create_audit_log(node, "update", node_params)
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
    node
  end

  def delete(conn, %{"id" => id}) do
    node = delete_node_and_tunnel(id)

    conn
    |> AuditManager.create_audit_log(node, "delete")
    |> put_flash(:info, "Клиент удален.")
    |> redirect_to_index_or_client_grp()
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
    |> AuditManager.create_audit_log(node, if(node.lock, do: "lock", else: "unlock"), node_params)
    |> put_flash(:info, "Клиент #{node.name} #{if node.lock, do: "за", else: "раз"}блокирован.")
    |> redirect(to: NavigationHistory.last_path(conn, 1))
  end

  def qr(conn, %{"clients_list" => clients_list} = params) do

    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render("qr.html", clients_list: clients_list)
  end



  def exec_selected(conn, params = %{"clients_list" => ids, "operation" => "work-order"}) do
    conn
    |> redirect(to: Routes.node_path(conn, :qr, clients_list: ids))
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
    |> AuditManager.create_audit_log(
      "clients",
      operation,
      params
      |> Enum.reject(fn
        {"_" <> _, _} -> true
        _ -> false
      end)
      |> Enum.into(%{})
    )
    |> redirect_to_index_or_client_grp()
  end

  def redirect_to_index_or_client_grp(conn) do
    conn
    |> redirect(
      to:
        NavigationHistory.last_paths(conn)
        |> Enum.find(fn x -> String.match?(x, ~r{/nodes/grp/\d+}) end) ||
          Routes.node_path(conn, :index)
    )
  end

  def client_comment_del(%{assigns: %{current_user: %{is_admin: true}}} = conn, %{"id" => id}) do
    client_comment = ClientCommentManager.get_client_comment!(id)
    {:ok, _} = ClientCommentManager.delete_client_comment(client_comment)

    conn
    |> put_flash(:info, "Комментарий удален")
    |> sleep_before_response()
    |> redirect(to: NavigationHistory.last_path(conn, 1))
  end

  def client_comment_del(conn, %{"id" => _id}) do
    conn
    |> put_flash(:error, "Только администратор может удалять чужие комментарии")
    |> sleep_before_response()
    |> redirect(to: NavigationHistory.last_path(conn, 1))
  end

  def client_comment_new(conn, params) do
    comment_id = params["comment_id"]

    if is_binary(comment_id) and String.match?(comment_id, ~r{\d+}) do
      client_comment = ClientCommentManager.get_client_comment!(comment_id)
      comment = params["comment"]

      if is_binary(comment) and String.trim(comment) != "" do
        case ClientCommentManager.update_client_comment(client_comment, params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Комментарий обновлен")

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(
              :error,
              "Ошибка при обновлении комментария: #{inspect(changeset.errors)}"
            )
        end
      else
        {:ok, _} = ClientCommentManager.delete_client_comment(client_comment)

        conn
        |> put_flash(:info, "Комментарий удален")
      end
    else
      case ClientCommentManager.create_client_comment(params) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Комментарий добавлен")

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "Ошибка при добавлении комментария: #{inspect(changeset.errors)}")
      end
    end
    |> sleep_before_response()
    |> redirect(to: NavigationHistory.last_path(conn))
  end

  defp sleep_before_response(conn) do
    Process.sleep(1000)
    conn
  end
end
