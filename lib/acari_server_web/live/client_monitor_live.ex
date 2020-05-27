defmodule AcariServerWeb.ClientMonitorLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(%{"hash" => hash}, _session, socket) do
    node = AcariServer.NodeManager.get_node_by_hash(hash) || AcariServer.NodeManager.get_node!(1)
    {:ok, assign(socket, node: node)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

end
