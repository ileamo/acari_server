defmodule AcariServerWeb.ClientMonitorLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(%{"hash" => "test"}, _session, socket) do
    socket |> mount_client(AcariServer.NodeManager.get_node!(1))
  end

  def mount(%{"hash" => hash}, _session, socket) do
    socket |> mount_client(AcariServer.NodeManager.get_node_by_hash(hash))
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp mount_client(socket, %AcariServer.NodeManager.Node{} = node) do
    ports = %{}

    ports =
      AcariServer.Mnesia.get_link_list_for_tunnel(node.name)
      |> Enum.group_by(fn %{name: name} -> name end)
      |> merge_ports(ports, :links)

    ports =
      (AcariServer.Mnesia.get_tunnel_state(node.name)[:errormsg] || %{})
      |> merge_ports(ports, :errormsg)

    ports =
      AcariServer.Mnesia.get_zabbix(node.name)
      |> Enum.group_by(fn %{key: key} ->
        case Regex.run(~r/\[([^\[\]]+)\]/, key) do
          [_, name] -> name
          _ -> nil
        end
      end,
      fn %{key: key, value: value, timestamp: ts} -> {key, [value: value, timestamp: ts]} end
      )
      |> Enum.map(fn {port, list} -> {port, list |> Enum.into(%{})} end)
      |> Enum.into(%{})
      |> merge_ports(ports, :zbx)

    client =
      %{node: node, ports: ports}

    {:ok, assign(socket, client: client)}
  end

  defp mount_client(socket, _) do
    {:ok, assign(socket, client: nil)}
  end

  defp merge_ports(map, ports, key) do
    Enum.reduce(map, ports, fn {port, value}, ports ->
      put_in(ports, [Access.key(port, %{}), key], value)
    end)
  end
end
