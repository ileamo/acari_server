defmodule AcariServerWeb.UserController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.UserManager
  alias AcariServer.UserManager.User

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin

  def index(conn, _params) do
    users = UserManager.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = UserManager.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case UserManager.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Пользователь успешно создан.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    changeset = UserManager.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = UserManager.get_user!(id)

    case UserManager.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Пользователь отредактирован.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    {:ok, _user} = UserManager.delete_user(user)

    conn
    |> put_flash(:info, "Пользователь удален.")
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
