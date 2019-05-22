defmodule AcariServerWeb.TerminalChannel do
  use AcariServerWeb, :channel
  alias AcariServer.Terminal
  require Logger

  def join("terminal:" <> _id, payload, socket) do
    with [_, tun_name] when is_binary(tun_name) <- Regex.run(~r|/([^/]+)$|, payload["pathname"]),
         node when not is_nil(node) <- AcariServer.Mnesia.get_main_server(tun_name),
         {:ok, terminal} <-
           Terminal.start_child(Node.self(), %{output_pid: self(), tun_name: tun_name}) do
      Process.link(terminal) |> IO.inspect()
      {:ok, assign(socket, :terminal, terminal)}
    else
      err ->
        Logger.error("Can't start terminal #{payload["pathname"]}: #{inspect(err)}")
        # Restart erlexec
        Process.exit(Process.whereis(:exec), :kill)
        {:error, %{reason: "terminal error"}}
    end
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
