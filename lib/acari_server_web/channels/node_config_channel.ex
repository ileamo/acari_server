defmodule AcariServerWeb.NodeConfigChannel do
  use AcariServerWeb, :channel

  def join("node_config:" <> _id, payload, socket) do
    pathname = payload["pathname"]
    {:ok, assign(socket, :pathname, pathname)}
  end

  def handle_in("input", %{"input" => input}, socket) do
    IO.inspect({input, socket}, label: "INPUT")
    [_, tun_name] = Regex.run(~r|/([^/]+)$|, socket.assigns[:pathname])
    AcariServer.Master.send_config(tun_name)
    {:noreply, socket}
  end
end
