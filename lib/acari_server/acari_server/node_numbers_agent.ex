defmodule AcariServer.NodeNumbersAgent do
  use Agent
  alias AcariServerWeb.Endpoint

  @max_items 25

  def start_link(_) do
    Agent.start_link(fn -> [[], [], []] end, name: __MODULE__)
  end

  # API

  def get() do
    Agent.get(__MODULE__, fn [ts_list, num_list, _] ->
      [ts_list, num_list]
    end)
  end

  def get_down_count() do
    Agent.get(__MODULE__, fn [_, _, down_list] ->
      down_list
      |> length()
    end)
  end

  def update() do
    Agent.update(
      __MODULE__,
      fn [ts_list, num_list, down_list] = state ->
        bad_nodes = AcariServer.Mnesia.get_down_tun_num()
        nodes_num = AcariServer.Mnesia.get_tunnels_num()
        num = nodes_num - bad_nodes
        prev = List.first(num_list)

        case num == prev do
          true ->
            state

          _ ->
            Endpoint.broadcast!("room:lobby", "link_event", %{
              redraw_chart: true
            })

            AcariServer.Zabbix.ZbxApi.zbx_send_master(
              "acari.clients.number",
              to_string(nodes_num)
            )

            AcariServer.Zabbix.ZbxApi.zbx_send_master("acari.clients.active", to_string(num))

            ts = :os.system_time(:second)

            [
              [ts | ts_list] |> Enum.take(@max_items),
              [num | num_list] |> Enum.take(@max_items),
              case num < (prev || num) do
                true -> [ts | down_list]
                _ -> down_list
              end
              |> Enum.take_while(fn x -> x > ts - 60 * 60 * 24 end)
            ]
        end
      end
    )
  end
end
