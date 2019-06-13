defmodule AcariServerWeb.NodeMonitorChannel do
  use AcariServerWeb, :channel
  alias AcariServer.NodeMonitor

  def join("node_monitor:" <> _id, payload, socket) do
    {:ok, node_monitor} =
      NodeMonitor.start_link(%{output_pid: self(), pathname: payload["pathname"]})

    {:ok, assign(socket, :node_monitor, node_monitor)}
  end

  def handle_in("input", params, socket) do
    NodeMonitor.get_input(socket.assigns[:node_monitor], params)

    {:noreply, socket}
  end

  def handle_info({:output, id, data, opt}, socket) do
    push(socket, "output", %{id: id, data: data, opt: opt})
    {:noreply, socket}
  end
end
