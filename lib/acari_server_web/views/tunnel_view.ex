defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def list_groups() do
    AcariServer.GroupManager.list_groups()
    |> Enum.sort_by(fn %{name: name} -> name end)
  end

  defp get_down_pc_m(state, up) do
    tm = :erlang.system_time(:second)
    total = tm - state.tm_start
    last_down_tm = if up, do: 0, else: tm - state.tm_down_start
    down = state.tm_down + last_down_tm
    {interval_to_text(last_down_tm), down * 100 / total}
  end

  defp interval_to_text(tm) do
    cond do
      tm < 60 * 2 -> "#{tm} сек."
      tm < 60 * 60 * 2 -> "#{div(tm, 60)} мин."
      true -> "#{div(tm, 60*60)} час."
    end
  end

  def get_sensors_html(name) do
    render(__MODULE__, "sensors.html", sensors: get_sensors(name))
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
    (AcariServer.Mnesia.get_zabbix(name) || [])
    |> Enum.sort_by(&Map.get(&1, :key))
  end

  def links_sorted(links_state) do
    (links_state || [])
    |> Enum.map(fn %{name: name, server_id: srv, up: up, state: state} ->
      %{
        name_srv: "#{name}@#{AcariServer.Mnesia.get_server_name_by_system_name(srv)}",
        up: up,
        state: state
      }
    end)
    |> Enum.sort_by(fn %{name_srv: ns} -> ns end)
  end
end
