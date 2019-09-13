defmodule AcariServerWeb.GrpOperController do
  use AcariServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", group_id: nil, group_name: "Все")
  end
end
