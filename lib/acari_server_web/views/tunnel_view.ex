defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def list_groups() do
    AcariServer.GroupManager.list_groups()
    |> Enum.sort_by(fn %{name: name} -> name end)
  end

  def get_tunnel_list(nodes) do
    tuns =
      :ets.tab2list(:tuns)
      |> Enum.map(fn {name, _, _, state} -> {name, state} end)
      |> Enum.into(%{})

    nodes
    |> Enum.map(fn %{name: n, description: d} -> %{name: n, description: d} end)
    |> Enum.map(fn %{name: name} = m -> Map.merge(m, get_sslinks(tuns[name])) end)
    |> Enum.map(fn
      %{links_up: nil} = m -> Map.put(m, :alert, 1)
      %{links_down: nil} = m -> Map.put(m, :alert, 3)
      m -> Map.put(m, :alert, 2)
    end)
  end

  def get_tunnel(name) do
    node = AcariServer.NodeManager.get_node_by_name(name)

    state =
      case :ets.lookup(:tuns, name) do
        [{_, _, _, state}] ->
          links =
            Acari.get_all_links(name)
            |> Enum.map(fn [k, v] -> {k, v} end)
            |> Enum.into(%{})

          links_state =
            state.sslinks
            |> Enum.map(fn {link_name, %{up: up, down_count: dc}} ->
              {link_name,
               %{down_count: dc, adm_state: (up && "UP") || "DOWN"}
               |> Map.merge(get_link_params(links[link_name]))
               |> Map.put(:csq, AcariServer.Zabbix.LastDataAgent.get(name, "csq[#{link_name}]") |> elem(0) )}
            end)

          %{
            links_state: links_state,
            inventory: state.inventory,
            telemetry: state.telemetry
          }

        _ ->
          %{}
      end

    %{description: node.description} |> Map.merge(state)
  end

  def get_sensors_html(name) do
    render(__MODULE__, "sensors.html", sensors: AcariServer.Zabbix.LastDataAgent.get(name))
  end

  def get_sensors_html(:string, name) do
    render_to_string(__MODULE__, "sensors.html", sensors: get_sensors(name))
  end

  defp get_sensors(name) do
    (AcariServer.Zabbix.LastDataAgent.get(name) || [])
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp get_link_params(nil), do: %{}

  defp get_link_params(link) do
    %{latency: link[:latency]}
  end

  defp get_sslinks(nil), do: %{links_up: nil, links_down: nil}

  defp get_sslinks(tun_state) do
    tun_state.sslinks
    |> Enum.reduce(
      %{links_up: [], links_down: []},
      fn
        {name, %{up: true}}, %{links_up: links_up} = acc ->
          %{acc | links_up: [name | links_up]}

        {name, %{up: _}}, %{links_down: links_down} = acc ->
          %{acc | links_down: [name | links_down]}
      end
    )
    |> Enum.map(fn
      {k, []} -> {k, nil}
      {k, list} -> {k, Enum.join(list, ", ")}
    end)
    |> Enum.into(%{})
  end
end
