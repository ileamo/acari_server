defmodule AcariServerWeb.NodeMonitorChannel do
  use AcariServerWeb, :channel
  alias AcariServer.NodeMonitor

  def join("node_monitor:" <> _id, payload, socket) do
    user_id = socket.assigns[:current_user_id]
    user = AcariServer.UserManager.get_user(user_id)
    [_, tun_name] = Regex.run(~r|/([^/]+)$|, payload["pathname"])

    rights =
      case user.is_admin do
        true ->
          "admin"

        _ ->
          AcariServer.UserManager.get_user_node_rights(
            user,
            AcariServer.NodeManager.get_node_by_name(tun_name).id
          )
      end

    {:ok, node_monitor} =
      NodeMonitor.start_link(%{output_pid: self(), tun_name: tun_name, rights: rights})

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
