defmodule AcariServerWeb.PageController do
  use AcariServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def secret(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "secret.html", current_user: user)
  end
end
