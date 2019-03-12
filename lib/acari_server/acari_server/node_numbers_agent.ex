defmodule AcariServer.NodeNumbersAgent do
  use Agent
  alias AcariServerWeb.Endpoint

  @max_items 25

  def start_link(_) do
    Agent.start_link(fn -> [[], []] end, name: __MODULE__)
  end

  # API

  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def update() do
    Agent.update(
      __MODULE__,
      fn [ts_list, num_list] = state ->
        {bad_nodes, _bad_links} = Acari.LinkEventAgent.get_failures()
        nodes_num = AcariServer.Master.get_nodes_num()
        num = nodes_num - bad_nodes

        case num == List.first(num_list) do
          true ->
            state

          _ ->
            Endpoint.broadcast!("room:lobby", "link_event", %{
              redraw_chart: true
            })

            [
              [:os.system_time(:second) | ts_list] |> Enum.take(@max_items),
              [num | num_list] |> Enum.take(@max_items)
            ]
        end
      end
    )
  end
end
