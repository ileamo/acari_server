defmodule AcariServerWeb.ClientMonitorLive.Radio do
  use Phoenix.LiveComponent
  @impl true
  def mount(socket) do
    {:ok, assign(socket, first: true)}
  end

  @impl true
  def update(%{timer: true}, socket) do
    tm = :erlang.system_time(:second)

    if socket.assigns[:tm_up_start] && tm - socket.assigns[:tm_up_start] <= 120 do
      uptime = AcariServerWeb.TunnelView.interval_to_text(tm - socket.assigns[:tm_up_start])

      uptime_timer = send_uptime_timer(socket, 1_000)

      {:ok, assign(socket, uptime: uptime, uptime_timer: uptime_timer)}
    else
      {:ok, socket}
    end
  end

  def update(assigns, socket) do
    # IO.inspect(socket.assigns, label: "MAIN")
    client_name = assigns.client_name
    port_name = assigns.id
    sensor = "csq[#{port_name}]"

    csq =
      AcariServer.Mnesia.get_zabbix(client_name)
      |> Enum.reduce_while(0, fn
        %{key: ^sensor, value: value}, _acc -> {:halt, value}
        _, acc -> {:cont, acc}
      end)

    {up, tm_up_start, uptime} =
      AcariServer.Mnesia.get_link_list_for_tunnel(client_name)
      |> Enum.group_by(fn %{name: name} -> name end)
      |> Map.get(port_name)
      |> port_up()

    wizard =
      if up do
        %{}
      else
        ((AcariServer.Mnesia.get_tunnel_state(client_name)[:wizard] || %{})
         |> Enum.group_by(fn {key, _} -> AcariServerWeb.TunnelView.get_arg(key) end)
         |> Map.get(port_name) ||
           %{})
        |> Enum.map(fn {key, val} ->
          [key] = Regex.run(~r/[^\[]+/, key)
          {key, val}
        end)
        |> Enum.into(%{})
      end

    uptime_timer =
      if socket.assigns.first ||
           tm_up_start != socket.assigns[:tm_up_start] do
        send_uptime_timer(socket, 1000, port_name)
      end

    wizard_snd_tm =
      if !socket.assigns.first && !up do
        tm = :os.system_time(:second)

        if tm - socket.assigns.wizard_snd_tm > 60 do
          AcariServer.Master.exec_script_on_peer(client_name, "nsgwizard_exec", %{
            "port" => port_name
          })

          tm
        end
      end

    {:ok,
     assign(socket,
       first: false,
       client_name: client_name,
       port_name: port_name,
       up: up,
       uptime: uptime,
       tm_up_start: tm_up_start,
       uptime_timer: uptime_timer,
       csq: csq,
       error: wizard["errormsg"][:value] || "Идет поиск неисправности...",
       wizard: wizard,
       wizard_snd_tm: wizard_snd_tm || socket.assigns[:wizard_snd_tm] || 0
     )}
  end

  defp send_uptime_timer(socket, timeout, id \\ nil) do
    ref = socket.assigns[:uptime_timer]

    if ref do
      Process.cancel_timer(socket.assigns[:uptime_timer])
    end

    Process.send_after(self(), {:timer, socket.assigns[:port_name] || id}, timeout)
  end

  defp port_up(links) do
    up =
      (links || [])
      |> Enum.reduce_while(false, fn
        %{up: true}, _ -> {:halt, true}
        _, _ -> {:cont, false}
      end)

    {tm_up_start, uptime} =
      if up do
        tm_up_start =
          (links
           |> Enum.min_by(fn %{state: %{tm_up_start: tm}} -> tm end)).state.tm_up_start

        {
          tm_up_start,
          AcariServerWeb.TunnelView.interval_to_text(:erlang.system_time(:second) - tm_up_start)
        }
      else
        {nil, nil}
      end

    {up, tm_up_start, uptime}
  end

  @grey "#ccc"
  defp get_signal_level_colors(csq) when is_binary(csq) do
    csq =
      case Integer.parse(csq) do
        {csq, _} -> csq
        _ -> nil
      end

    lines =
      case csq do
        x when x in 4..9 -> 1
        x when x in 10..14 -> 2
        x when x in 15..19 -> 3
        x when x in 20..31 -> 4
        _ -> 0
      end

    List.duplicate("blck", lines) ++ List.duplicate(@grey, 4 - lines)
  end

  defp get_signal_level_colors(_), do: List.duplicate(@grey, 4)

  defp get_value(val) do
    with str when is_binary(str) <- val,
         val when val != "" <- String.trim(val) do
      val
    else
      _ -> false
    end
  end
end
