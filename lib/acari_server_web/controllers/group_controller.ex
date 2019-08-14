defmodule AcariServerWeb.GroupController do
  use AcariServerWeb, :controller

  alias AcariServer.GroupManager
  alias AcariServer.GroupManager.Group

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new]

  def index(conn, _params) do
    groups = GroupManager.list_groups()
    render(conn, "index.html", groups: groups)
  end

  def new(conn, _params) do
    changeset = GroupManager.change_group(%Group{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"group" => group_params}) do
    case GroupManager.create_group(group_params) do
      {:ok, group} ->
        conn
        |> put_flash(:info, "Группа успешно создана.")
        |> redirect(to: Routes.group_path(conn, :show, group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)
    render(conn, "show.html", group: group)
  end

  def edit(conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)
    changeset = GroupManager.change_group(group)
    render(conn, "edit.html", group: group, changeset: changeset)
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    group = GroupManager.get_group!(id)

    case GroupManager.update_group(group, group_params) do
      {:ok, group} ->
        conn
        |> put_flash(:info, "Группа отредактирована.")
        |> redirect(to: Routes.group_path(conn, :show, group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", group: group, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)
    {:ok, _group} = GroupManager.delete_group(group)

    conn
    |> put_flash(:info, "Группа удалена.")
    |> redirect(to: Routes.group_path(conn, :index))
  end

  def oper(conn, %{"id" => id}) do
    group = GroupManager.get_group!(id)
    render(conn, "oper.html", group: group)
  end
end
