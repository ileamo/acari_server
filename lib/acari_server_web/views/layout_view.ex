defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  defdelegate num_of_mes(), to: Acari.LinkEventAgent, as: :get_length

  def get_mes() do
    [node() | Node.list()]
    |> Enum.sort()
    |> Enum.map(fn node ->
      [node, Agent.get({Acari.LinkEventAgent, node}, Acari.LinkEventAgent, :get_state, [])]
    end)
    # reject servers with empty mesage list
    |> Enum.reject(fn
      [_, []] -> true
      _ -> false
    end)
    |> Enum.map(fn [server, mes_list] ->
      [
        server,
        mes_list
        |> Enum.map(fn
          {tun, link, ts} when is_binary(link) ->
            {"warning", "#{get_local_time(ts)} #{tun}", "#{link}: нет связи"}

          {tun, _, ts} ->
            {"danger", "#{get_local_time(ts)} #{tun}", "Не доступно"}
        end)
      ]
    end)
  end

  defp get_local_time(system_time) do
    {_, {h, m, s}} = :calendar.system_time_to_local_time(system_time, :second)
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
  end
end
