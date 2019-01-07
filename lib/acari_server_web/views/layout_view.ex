defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  defdelegate num_of_mes(), to: Acari.LinkEventAgent, as: :get_length
  defdelegate get_mes(), to: Acari.LinkEventAgent, as: :get
end
