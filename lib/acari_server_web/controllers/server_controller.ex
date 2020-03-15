defmodule AcariServerWeb.ServerController do
  use AcariServerWeb, :controller

  alias AcariServer.ServerManager
  alias AcariServer.ServerManager.Server
  alias AcariServer.AuditManager

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new]

  def index(conn, _params) do
    servers = ServerManager.list_servers()
    render(conn, "index.html", servers: servers)
  end

  def new(conn, _params) do
    changeset = ServerManager.change_server(%Server{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"server" => server_params}) do
    case ServerManager.create_server(server_params) do
      {:ok, server} ->
        AcariServer.ServerMonitor.connect_all_nodes()

        conn
        |> AuditManager.create_audit_log(server, "create", server_params)
        |> put_flash(:info, "Сервер создан.")
        |> redirect(to: Routes.server_path(conn, :show, server, after_redirect: true))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    server = ServerManager.get_server!(id)
    render(conn, "show.html", server: server)
  end

  def edit(conn, %{"id" => id}) do
    server = ServerManager.get_server!(id)
    changeset = ServerManager.change_server(server)
    render(conn, "edit.html", server: server, changeset: changeset)
  end

  def update(conn, %{"id" => id, "server" => server_params}) do
    server = %{system_name: oldnode} = ServerManager.get_server!(id)

    case ServerManager.update_server(server, server_params) do
      {:ok, server} ->
        if oldnode != server_params["system_name"] do
          Node.disconnect(oldnode |> String.to_atom())
          AcariServer.ServerMonitor.connect_all_nodes()
        end

        conn
        |> AuditManager.create_audit_log(server, "update", server_params)
        |> put_flash(:info, "Сервер отредактирован.")
        |> redirect(to: Routes.server_path(conn, :show, server))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", server: server, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    server = ServerManager.get_server!(id)
    {:ok, _server} = ServerManager.delete_server(server)

    Node.disconnect(server.name |> String.to_atom())

    conn
    |> AuditManager.create_audit_log(server, "delete")
    |> put_flash(:info, "Сервер удален.")
    |> redirect(to: Routes.server_path(conn, :index))
  end
end
