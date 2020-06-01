defmodule AcariServerWeb.ClientMonitorLive.Radio do
  use Phoenix.LiveComponent
  @impl true
  def update(assigns, socket) do
    client_name = assigns.client_name
    port_name = assigns.id
    sensor = "csq[#{port_name}]"

    csq =
      AcariServer.Mnesia.get_zabbix(client_name)
      |> Enum.reduce_while(0, fn
        %{key: ^sensor, value: value}, _acc -> {:halt, value}
        _, acc -> {:cont, acc}
      end)

    up =
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

    {:ok,
     assign(socket,
       port_name: port_name,
       up: up,
       csq: csq,
       error: wizard["errormsg"][:value],
       wizard: wizard
     )}
  end

  defp port_up(links) do
    (links || [])
    |> Enum.reduce_while(false, fn
      %{up: true}, _ -> {:halt, true}
      _, _ -> {:cont, false}
    end)
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
end
