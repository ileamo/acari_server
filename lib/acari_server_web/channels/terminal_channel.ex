defmodule AcariServerWeb.TerminalChannel do
  use AcariServerWeb, :channel
  alias AcariServer.Terminal
  require Logger

  def join("terminal:1", payload, socket) do
    with [_, tun_name] when is_binary(tun_name) <- Regex.run(~r|/([^/]+)$|, payload["pathname"]),
         node when not is_nil(node) <- AcariServer.Mnesia.get_main_server(tun_name),
         dstaddr when is_binary(dstaddr) <- AcariServer.Master.get_dstaddr(tun_name) do
      with {:ok, terminal} <-
             Terminal.start_child(node, %{
               output_pid: self(),
               tun_name: tun_name,
               command: 'ssh root@#{dstaddr} -o StrictHostKeyChecking=no'
             }) do
        Process.link(terminal)
        {:ok, assign(socket, :terminal, terminal)}
      else
        err ->
          Logger.error("Can't start terminal #{tun_name}: #{inspect(err)}")
          # Restart erlexec
          Process.exit(:rpc.call(node, Process, :whereis, [:exec]), :kill)
          {:error, %{reason: "terminal error"}}
      end
    else
      _ -> {:error, %{reason: "bad pathname: #{payload["pathname"]}"}}
    end
  end

  def join("terminal:2", _payload, socket) do
    with {:ok, terminal} <-
           Terminal.start_child(Node.self(), %{
             output_pid: self(),
             tun_name: AcariServer.Mnesia.get_server_name_by_system_name(node()),
             command: '/bin/bash'
           }) do
      Process.link(terminal)
      {:ok, assign(socket, :terminal, terminal)}
    else
      err ->
        Logger.error("Can't start terminal server: #{inspect(err)}")
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
