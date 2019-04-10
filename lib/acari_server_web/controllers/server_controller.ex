defmodule AcariServerWeb.ServerController do
  use AcariServerWeb, :controller

  alias AcariServer.ServerManager
  alias AcariServer.ServerManager.Server

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
        Node.connect(server_params["name"] |> String.to_atom())

        conn
        |> put_flash(:info, "Сервер создан.")
        |> redirect(to: Routes.server_path(conn, :show, server))

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
    server = %{name: oldname} = ServerManager.get_server!(id)

    case ServerManager.update_server(server, server_params) do
      {:ok, server} ->
        if oldname != server_params["name"] do
          Node.disconnect(oldname |> String.to_atom())
          Node.connect(server_params["name"] |> String.to_atom())
        end

        conn
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
    |> put_flash(:info, "Сервер удален.")
    |> redirect(to: Routes.server_path(conn, :index))
  end
end
