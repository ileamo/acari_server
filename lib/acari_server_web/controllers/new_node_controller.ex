defmodule AcariServerWeb.NewNodeController do
  use AcariServerWeb, :controller

  alias AcariServer.NewNodeDiscovery
  alias AcariServer.NewNodeDiscovery.NewNode

  def index(conn, _params) do
    newnodes = NewNodeDiscovery.list_newnodes()
    render(conn, "index.html", newnodes: newnodes)
  end

  def new(conn, _params) do
    changeset = NewNodeDiscovery.change_new_node(%NewNode{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"new_node" => new_node_params}) do
    case NewNodeDiscovery.create_new_node(new_node_params) do
      {:ok, new_node} ->
        conn
        |> put_flash(:info, "New node created successfully.")
        |> redirect(to: Routes.new_node_path(conn, :show, new_node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    render(conn, "show.html", new_node: new_node)
  end

  def edit(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    changeset = NewNodeDiscovery.change_new_node(new_node)
    render(conn, "edit.html", new_node: new_node, changeset: changeset)
  end

  def update(conn, %{"id" => id, "new_node" => new_node_params}) do
    new_node = NewNodeDiscovery.get_new_node!(id)

    case NewNodeDiscovery.update_new_node(new_node, new_node_params) do
      {:ok, new_node} ->
        conn
        |> put_flash(:info, "New node updated successfully.")
        |> redirect(to: Routes.new_node_path(conn, :show, new_node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", new_node: new_node, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    {:ok, _new_node} = NewNodeDiscovery.delete_new_node(new_node)

    conn
    |> put_flash(:info, "New node deleted successfully.")
    |> redirect(to: Routes.new_node_path(conn, :index))
  end
end
