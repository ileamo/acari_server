defmodule AcariServerWeb.SessionController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.{UserManager, UserManager.User, UserManager.Guardian}
  alias AcariServer.AuditManager


  def new(conn, _params) do
    changeset = UserManager.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)

    if maybe_user do
      redirect(conn, to: NavigationHistory.last_path(conn, default: "/"))
    else
      conn
      |> put_layout(false)
      |> render("new.html",
        changeset: changeset,
        action: Routes.session_path(conn, :login)
      )
    end
  end

  def login(conn, %{
        "user" => %{"username" => username, "password" => password}
      }) do
    UserManager.authenticate_user(username, password)
    |> login_reply(conn, username)
  end

  def logout(conn, _) do
    username =
      get_in(conn, [
        Access.key(:private, %{}),
        Access.key(:guardian_default_resource, %{}),
        Access.key(:username)
      ])

      Logger.info("User #{username} logged out")

    conn
    |> AuditManager.create_audit_log({"auth", username}, "logout")
    |> Guardian.Plug.sign_out()
    |> redirect(to: "/login")
  end

  defp login_reply({:ok, user}, conn, username) do
    Logger.info("User #{username} logged in")


    conn
    |> AuditManager.create_audit_log({"auth", username}, "login")
    |> put_flash(:success, "Welcome back!")
    |> Guardian.Plug.sign_in(%{
      user: user,
      remote_ip: conn.remote_ip,
      user_agent: conn.req_headers |> Enum.into(%{}) |> Map.get("user-agent")
    })
    |> redirect(to: NavigationHistory.last_path(conn, default: "/"))
  end

  defp login_reply({:error, _reason}, conn, username) do
    Logger.info("User #{username} is not logged in")

    conn
    |> AuditManager.create_audit_log({"auth", username}, "logerr")
    |> put_flash(:error, "Неверный пароль")
    |> new(%{})
  end
end
