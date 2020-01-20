defmodule AcariServerWeb.SessionController do
  use AcariServerWeb, :controller
  require Logger

  alias AcariServer.{UserManager, UserManager.User, UserManager.Guardian}

  def new(conn, params = %{"prev_path" => _prev_path}), do: new_aux(conn, params)
  def new(conn, _), do: new_aux(conn, %{"prev_path" => "/"})

  defp new_aux(conn, %{"prev_path" => prev_path}) do
    changeset = UserManager.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)

    if maybe_user do
      redirect(conn, to: prev_path)
    else
      conn
      |> put_layout(false)
      |> render("new.html",
        changeset: changeset,
        action: Routes.session_path(conn, :login),
        prev_path: prev_path
      )
    end
  end

  def login(conn, %{
        "user" => %{"username" => username, "password" => password, "prev_path" => prev_path}
      }) do
    UserManager.authenticate_user(username, password)
    |> login_reply(conn, prev_path, username)
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
    |> Guardian.Plug.sign_out()
    |> redirect(to: "/login")
  end

  defp login_reply({:ok, user}, conn, prev_path, username) do
    Logger.info("User #{username} logged in")


    conn
    |> put_flash(:success, "Welcome back!")
    |> Guardian.Plug.sign_in(%{
      user: user,
      remote_ip: conn.remote_ip,
      user_agent: conn.req_headers |> Enum.into(%{}) |> Map.get("user-agent")
    })
    |> redirect(to: prev_path)
  end

  defp login_reply({:error, _reason}, conn, _prev_path, username) do
    Logger.info("User #{username} is not logged in")

    conn
    |> put_flash(:error, "Неверный пароль")
    |> new(%{})
  end
end
