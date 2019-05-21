defmodule AcariServerWeb.TerminalChannel do
  use AcariServerWeb, :channel
  alias AcariServer.Terminal
  require Logger

  def join("terminal:" <> _id, payload, socket) do
    with [_, tun_name] when is_binary(tun_name) <- Regex.run(~r|/([^/]+)$|, payload["pathname"]),
    node when not is_nil(node) <- AcariServer.Mnesia.get_main_server(tun_name),
    %Task{ref: ref} <-
           Task.Supervisor.async_nolink(
             {AcariServer.TaskSup, node},
             Terminal,
             :start_link,
             [
               %{output_pid: self(), tun_name: tun_name}
             ]
           ) do
      {:ok, assign(socket, :ref, ref)}
    else
      err ->
        Logger.error("Can't start terminal #{payload["pathname"]}: #{inspect(err)}")
        {:error, %{reason: "terminal error"}}
    end
  end

  def handle_in("input", %{"input" => input}, socket) do
    # Logger.debug("TerminalChannel: input: #{inspect(input)}")
    Terminal.send_input(socket.assigns[:terminal], input)
    {:noreply, socket}
  end

  def handle_info({:output, output}, socket) do
    # Logger.debug("TerminalChannel: output: #{inspect(output)}")
    push(socket, "output", %{output: output})
    {:noreply, socket}
  end

  def handle_info({ref, {:ok, terminal}}, %{assigns: %{ref: ref}} = socket) do
    Logger.info("TerminalChannel: get terminal: #{inspect(terminal)}")
    Process.link(terminal)
    {:noreply, assign(socket, :terminal, terminal)}
  end

  def handle_info({ref, {:error, err}}, %{assigns: %{ref: ref}} = socket) do
    Logger.error("Can't start terminal: #{inspect(err)}")
    # Restart erlexec
    Process.exit(Process.whereis(:exec), :kill)
    {:stop, :shutdown, socket}
  end

  def handle_info({:DOWN, ref, :process, _pid, :normal}, %{assigns: %{ref: ref}} = socket) do
    {:noreply, socket}
  end

  def handle_info(mes, socket) do
    Logger.warn("TerminalChannel: bad message: #{inspect(mes)}")
    {:noreply, socket}
  end
end
