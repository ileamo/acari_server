defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  defdelegate num_of_mes(), to: Acari.LinkEventAgent, as: :get_length

  def get_mes() do
    Acari.LinkEventAgent.get()
    |> Enum.map(fn
      {tun, link, ts} when is_binary(link) ->
        {"warning", "#{ts} #{tun}", "#{link}: нет связи"}

      {tun, _, ts} ->
        {"danger", "#{ts} #{tun}", "Не доступно"}
    end)
  end
end
