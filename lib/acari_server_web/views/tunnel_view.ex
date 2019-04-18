defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def list_groups() do
    AcariServer.GroupManager.list_groups()
    |> Enum.sort_by(fn %{name: name} -> name end)
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
            |> Enum.map(fn {link_name, %{up: up, down_count: dc} = sslink_state} ->
              {link_name,
               %{
                 down_pc: get_down_pc(sslink_state),
                 down_count: dc,
                 adm_state: (up && "UP") || "DOWN"
               }
               |> Map.merge(get_link_params(links[link_name]))
               |> Map.put(
                 :csq,
                 (AcariServer.Zabbix.LastDataAgent.get(name, "csq[#{link_name}]") || {nil})
                 |> elem(0)
               )}
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

  defp get_down_pc(sslink_state) do
    tm = :erlang.system_time(:second)
    total = tm - sslink_state.tm_start
    down = sslink_state.tm_down + if sslink_state.up, do: 0, else: tm - sslink_state.tm_down_start
    down * 100 / total
  end

  defp get_down_pc_m(state, up) do
    tm = :erlang.system_time(:second)
    total = tm - state.tm_start
    down = state.tm_down + if up, do: 0, else: tm - state.tm_down_start
    down * 100 / total
  end



  def get_sensors_html(name) do
    render(__MODULE__, "sensors.html", sensors: AcariServer.Zabbix.LastDataAgent.get(name))
  end

  def get_sensors_html(:string, name) do
    render_to_string(__MODULE__, "sensors.html", sensors: get_sensors(name))
  end

  def pretty_time(mks) do
    case mks do
      n when is_number(n) ->
        cond do
          n > 2000 ->
            "#{(n / 1000) |> round()} ms"

          true ->
            "#{n / 1000} ms"
        end

      _ ->
        nil
    end
  end

  defp get_sensors(name) do
    (AcariServer.Zabbix.LastDataAgent.get(name) || [])
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp get_link_params(nil), do: %{}

  defp get_link_params(link) do
    %{latency: link[:latency]}
  end
end
