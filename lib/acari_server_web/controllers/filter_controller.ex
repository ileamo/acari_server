defmodule AcariServerWeb.FilterController do
  use AcariServerWeb, :controller

  alias AcariServer.FilterManager
  alias AcariServer.FilterManager.Filter

  def index(conn, _params) do
    filrers = FilterManager.list_filrers()
    render(conn, "index.html", filrers: filrers)
  end

  def new(conn, _params) do
    changeset = FilterManager.change_filter(%Filter{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{current_user: %{id: user_id}}} = conn, %{"filter" => filter_params}) do
    case FilterManager.create_filter(filter_params |> Map.put("user_id", user_id)) do
      {:ok, filter} ->
        conn
        |> put_flash(:info, "Filter created successfully.")
        |> redirect(to: Routes.filter_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    filter = FilterManager.get_filter!(id)
    render(conn, "show.html", filter: filter)
  end

  def edit(conn, %{"id" => id}) do
    filter = FilterManager.get_filter!(id)
    changeset = FilterManager.change_filter(filter)
    render(conn, "edit.html", filter: filter, changeset: changeset)
  end

  def update(conn, %{"id" => id, "filter" => filter_params}) do
    filter = FilterManager.get_filter!(id)

    case FilterManager.update_filter(filter, filter_params) do
      {:ok, filter} ->
        conn
        |> put_flash(:info, "Filter updated successfully.")
        |> redirect(to: Routes.filter_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", filter: filter, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    filter = FilterManager.get_filter!(id)
    {:ok, _filter} = FilterManager.delete_filter(filter)

    conn
    |> put_flash(:info, "Filter deleted successfully.")
    |> redirect(to: Routes.filter_path(conn, :index))
  end
end
