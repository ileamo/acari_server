defmodule AcariServerWeb.TunnelController do
  use AcariServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
