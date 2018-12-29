defmodule AcariServer.UserManager.ErrorHandler do
  import Plug.Conn
  alias AcariServerWeb.Router.Helpers, as: Routes

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> Phoenix.Controller.redirect(
      to: Routes.session_path(conn, :new, prev_path: "#{conn.request_path}?#{conn.query_string}")
    )
  end
end
