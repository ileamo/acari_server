defmodule AcariServer.UserManager.ErrorHandler do
  alias AcariServerWeb.Router.Helpers, as: Routes

  # def auth_error(%{request_path: "/login"} = conn, {_type, _reason}, _opts) do
  #  conn
  # end

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> Phoenix.Controller.redirect(
      to: Routes.session_path(conn, :new)
    )
  end
end
