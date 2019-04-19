defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def list_groups() do
    AcariServer.GroupManager.list_groups()
    |> Enum.sort_by(fn %{name: name} -> name end)
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
end
