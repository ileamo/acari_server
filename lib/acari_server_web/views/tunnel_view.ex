defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def list_groups() do
    AcariServer.GroupManager.list_groups()
    |> Enum.sort_by(fn %{name: name} -> name end)
  end

  defp get_down_pc_m(state, up) do
    tm = :erlang.system_time(:second)

    total =
      case tm - state.tm_start do
        0 -> 1
        other -> other
      end

    last_down_tm = if up, do: 0, else: tm - state.tm_down_start
    last_up_tm = if up, do: tm - (state[:tm_up_start] || tm), else: 0
    downtime = state.tm_down + last_down_tm
    uptime = total - downtime

    avg = interval_to_text(round(uptime / (state[:down_count] + if(up, do: 1, else: 0))))

    {interval_to_text(last_up_tm), interval_to_text(last_down_tm), interval_to_text(total),
     downtime * 100 / total, avg}
  end

  def interval_to_text(tm) do
    cond do
      tm < 60 * 2 -> "#{tm} сек."
      tm < 60 * 60 * 2 -> "#{round(tm / 60)} мин."
      tm < 60 * 60 * 24 * 2 -> "#{round(tm / (60 * 60))} час."
      true -> "#{round(tm / (60 * 60 * 24))} дн."
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

  def get_down_ports_msgs(name, links_state) do
    port_up = get_port_state(links_state)

    case AcariServer.Mnesia.get_tunnel_state(name)[:wizard] do
      %{} = map ->
        map
        |> Enum.group_by(fn {key, _} -> get_arg(key) end)
        |> Enum.reject(fn
          {nil, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {port, list} ->
          if !port_up[port] do
            params = Enum.into(list, %{})

            """
            <h5 class='mr-2'>#{port}</h5>
            #{wizard_errormsg(params, port)}
            #{wizard_value(params, port, "slot", "Слот")}
            #{wizard_value(params, port, "sim", "Сим карта")}
            #{wizard_value(params, port, "network", "Сеть")}
            #{wizard_value(params, port, "csq", "CSQ")}
            #{wizard_value(params, port, "rat", "Режим")}
            #{wizard_rest(params, port)}
            """
          end
        end)
        |> Enum.reject(&is_nil(&1))
        |> Enum.join("</br>")

      _ ->
        ""
    end
  end

  defp wizard_errormsg(params, port) do
    value = params["errormsg[#{port}]"][:value] || "Идет поиск неисправности..."

    date =
      case params["errormsg[#{port}]"][:timestamp] do
        nil -> ""
        ts -> AcariServer.get_local_date(ts) <> ":"
      end

    """
    <div>
      <span>#{date}</span>
      <strong class='text-danger'>#{value}</strong>
    </div>
    """
  end

  defp wizard_value(params, port, name, descr) do
    with value when is_binary(value) <- params["#{name}[#{port}]"][:value],
         value when value != "" <- String.trim(value) do
      "<strong>#{descr}:</strong> #{value}</br>"
    else
      _ -> ""
    end
  end

  defp wizard_rest(params, _port) do
    std_keys = ["errormsg", "slot", "sim", "network", "csq", "rat"]

    params
    |> Enum.map(fn {key, %{value: value}} ->
      [key] = Regex.run(~r/[^\[]+/, key)

      if !(key in std_keys) and String.trim(value) != "" do
        "<strong>#{key}:</strong> #{value}</br>"
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> IO.inspect()
  end

  def is_errormsg(name) do
    case AcariServer.Mnesia.get_tunnel_state(name)[:wizard] do
      %{} = map ->
        port_up =
          AcariServer.Mnesia.get_link_list_for_tunnel(name)
          |> get_port_state()

        case Enum.reject(map, fn {key, _} -> port_up[get_arg(key)] end) do
          [] ->
            false

          list ->
            list
            |> Enum.map(fn
              {"errormsg[" <> port, %{value: value}} ->
                "<strong>#{String.slice(port, 0..-2)}:</strong> #{value}"

              _ ->
                nil
            end)
            |> Enum.reject(&is_nil/1)
            |> Enum.join("</br>")
        end

      _ ->
        false
    end
  end

  defp get_port_state(links_state) do
    links_state
    |> Enum.reduce(%{}, fn %{id: {port, _, _}, up: up}, acc ->
      Map.put(acc, port, up || (acc[port] || false))
    end)
  end

  def redirect_path(conn) do
    NavigationHistory.last_paths(conn)
    |> Enum.find(fn x -> String.match?(x, ~r{^/tunnels($|/\d+$)}) end) ||
      Routes.node_path(conn, :index)
  end

  def get_arg(key) do
    case Regex.run(~r/\[([^\[\]]+)\]/, key) do
      [_, name] -> name
      _ -> nil
    end
  end

  def restarts_per_day(tun) do
    case tun[:client_restarts][:list] do
      list when is_list(list) ->
        ts = :os.system_time(:second)
        length(list |> Enum.reject(fn x -> ts - x >= 60*60*24 end))

      _ ->
        ""
    end
  end
end
