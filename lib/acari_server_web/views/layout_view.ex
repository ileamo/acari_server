defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end
end
