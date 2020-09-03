defmodule AcariServerWeb.FilterController do
  use AcariServerWeb, :controller

  alias AcariServer.FilterManager
  alias AcariServer.FilterManager.Filter

  plug :is_user_owner when action in [:edit, :delete]

  def is_user_owner(
        conn = %{assigns: %{current_user: %{id: user_id}}, params: %{"id" => filter_id}},
        _opts
      ) do
    if FilterManager.get_filter_wo_user!(filter_id).user_id == user_id do
      conn
    else
      AcariServer.UserManager.no_auth(conn, "Этот фильтр принадлежит другому пользователю")
    end
  end

  def index(%{assigns: %{current_user: %{is_admin: true}}} = conn, _params) do
    filrers = FilterManager.list_filters()
    render(conn, "index.html", filrers: filrers)
  end

  def index(%{assigns: %{current_user: %{id: user_id}}} = conn, _params) do
    filrers =
      FilterManager.list_filters()
      |> Enum.filter(fn %{user_id: id} -> id == user_id end)

    render(conn, "index.html", filrers: filrers)
  end

  def new(conn, _params) do
    changeset = FilterManager.change_filter(%Filter{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{current_user: %{id: user_id}}} = conn, %{"filter" => filter_params}) do
    case FilterManager.create_filter(filter_params |> Map.put("user_id", user_id)) do
      {:ok, _filter} ->
        conn
        |> put_flash(:info, "Filter created successfully.")
        |> redirect(to: Routes.grp_oper_path(conn, :index))

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

  def update(conn = %{assigns: %{current_user: %{is_admin: is_admin}}}, %{
        "id" => id,
        "filter" => filter_params
      }) do
    filter = FilterManager.get_filter!(id)

    filter_params =
      case is_admin do
        true -> filter_params
        _ -> filter_params |> Map.put("common", "false")
      end

    case FilterManager.update_filter(filter, filter_params) do
      {:ok, _filter} ->
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
