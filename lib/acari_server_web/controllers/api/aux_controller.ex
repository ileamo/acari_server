defmodule AcariServerWeb.Api.AuxController do
  use AcariServerWeb, :controller

  def nodes_num(conn, _) do
    render(conn, "result.json")
  end
end
