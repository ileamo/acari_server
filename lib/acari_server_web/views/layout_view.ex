defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  defdelegate num_of_mes(), to: Acari.LinkEventAgent, as: :get_length

  def get_mes() do
    x = get_mes_from_all_nodes()

    bad_nodes_list =
      case x do
        [] ->
          []

        x ->
          [head | tail] = x |> Enum.map(fn [_, {_, bad_list}] -> bad_list end)

          case head do
            [] ->
              []

            _ ->
              tail
              |> Enum.reduce_while(MapSet.new(head), fn
                [], _ -> {:halt, []}
                bad_list, acc -> {:cont, MapSet.intersection(acc, MapSet.new(bad_list))}
              end)
          end
      end

    {x, bad_nodes_list |> Enum.into([])}
  end

  defp get_mes_from_all_nodes() do
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
        |> Enum.map_reduce([], fn
          {tun, link, ts}, acc when is_binary(link) ->
            {{"info", "#{get_local_time(ts)} #{tun}", "#{link}: нет связи"}, acc}

          {tun, _, ts}, acc ->
            {{"warning", "#{get_local_time(ts)} #{tun}", "Не доступно"}, [tun | acc]}
        end)
      ]
    end)
  end

  defp get_local_time(system_time) do
    {_, {h, m, s}} = :calendar.system_time_to_local_time(system_time, :second)
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
  end
end
