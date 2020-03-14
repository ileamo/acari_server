defmodule AcariServerWeb.UserController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.UserManager
  alias AcariServer.UserManager.User
  alias AcariServer.AuditManager

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

  def create(conn, %{"user" => user_params} = params) do
    rights = params["rights"] || %{}

    case UserManager.create_user(user_params, rights) do
      {:ok, user} ->
        conn
        |> AuditManager.create_audit_log(user, "create", user_params |> modify(rights))
        |> put_flash(:info, "Пользователь успешно создан.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, rights: rights)
    end
  end

  def show(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def show_rw(conn, %{"id" => id}) do
    user = UserManager.get_user!(id, :rw)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    changeset = UserManager.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params} = params) do
    rights = params["rights"] || %{}
    user = UserManager.get_user!(id, :rw)

    case UserManager.update_user(user, user_params, rights) do
      {:ok, user} ->
        conn
        |> AuditManager.create_audit_log(
          user,
          "update",
          user_params |> modify(rights)
        )
        |> put_flash(:info, "Пользователь отредактирован.")
        |> redirect(to: Routes.user_path(conn, :show_rw, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset, rights: rights)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = UserManager.get_user!(id)
    {:ok, _user} = UserManager.delete_user(user)

    conn
    |> AuditManager.create_audit_log(user, "delete")
    |> put_flash(:info, "Пользователь удален.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  defp modify(params, rights) do
    params
    |> Map.drop(["password", "rpt_psw"])
    |> Map.put("rights", rights)
  end
end
