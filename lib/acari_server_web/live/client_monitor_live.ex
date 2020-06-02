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
    ports = ports_list(node)

    if connected?(socket) do
      Process.send_after(self(), :timer, 1000)
      Process.send_after(self(), :update, 5000)
    end

    Phoenix.PubSub.subscribe(AcariServer.PubSub, "wizard:#{node.name}")

    {:ok,
     assign(socket, node: node, ports: ports, local_time: AcariServer.get_local_time(:wo_date))}
  end

  defp mount_client(socket, _) do
    {:ok, assign(socket, node: nil, ports: [])}
  end

  @impl true
  def handle_info({:timer, id}, socket) do
    send_update(AcariServerWeb.ClientMonitorLive.Radio, id: id, timer: true)
    {:noreply, socket}
  end

  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 1000)
    {:noreply, assign(socket, local_time: AcariServer.get_local_time(:wo_date))}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 60_000)

    ports = ports_list(socket.assigns.node)

    new = ports -- socket.assigns.ports

    for name <- new do
      live_component(socket, AcariServerWeb.ClientMonitorLive.Radio,
        id: name,
        client_name: socket.assigns.node.name
      )
    end

    for name <- socket.assigns.ports do
      send_update(AcariServerWeb.ClientMonitorLive.Radio,
        id: name,
        client_name: socket.assigns.node.name
      )
    end

    node = AcariServer.NodeManager.get_node_rw!(socket.assigns.node.id)

    {:noreply, assign(socket, node: node, ports: ports)}
  end

  def handle_info(mes, socket) do
    IO.inspect(mes)
    {:noreply, socket}
  end

  defp ports_list(node) do
    ((AcariServer.Mnesia.get_link_list_for_tunnel(node.name)
      |> Enum.reduce([], fn %{name: name}, acc -> [name | acc] end)) ++
       ((AcariServer.Mnesia.get_tunnel_state(node.name)[:wizard] || [])
        |> Enum.reduce([], fn {key, _}, acc ->
          [AcariServerWeb.TunnelView.get_arg(key) | acc]
        end)))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
