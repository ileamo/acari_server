defmodule AcariServerWeb.TerminalChannel do
  use AcariServerWeb, :channel

  def join("terminal:" <> id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("input", %{"input" => input}, socket) do
    push(socket, "output", %{output: input})
    {:noreply, socket}
  end
end
