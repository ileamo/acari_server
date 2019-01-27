defmodule AcariServerWeb.TerminalChannel do
  use AcariServerWeb, :channel
  alias AcariServer.Terminal

  def join("terminal:" <> _id, _payload, socket) do
    {:ok, terminal} = Terminal.start_link(self())
    {:ok, assign(socket, :terminal, terminal)}
  end

  def handle_in("input", %{"input" => input}, socket) do
    Terminal.send_input(socket.assigns[:terminal], input)
    {:noreply, socket}
  end

  def handle_info({:output, output}, socket) do
    push(socket, "output", %{output: output})
    {:noreply, socket}
  end
end
