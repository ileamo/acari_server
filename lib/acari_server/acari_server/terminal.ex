defmodule AcariServer.Terminal do
  use GenServer

  def start_link(output_pid) do
    GenServer.start_link(__MODULE__, output_pid)
  end

  @impl true
  def init(output_pid) do
    {:ok, shell, _os_pid} = :exec.run('$SHELL', [:stdin, :stdout, :stderr, :pty])
    :exec.send(shell, "stty echo\n")

    {:ok,
     %{
       output_pid: output_pid,
       shell: shell
     }}
  end

  @impl true
  def handle_cast({:input, input}, %{shell: shell} = state) do
    :exec.send(shell, input)
    {:noreply, state}
  end

  @impl true
  def handle_info({:stdout, _os_pid, output}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, output})
    {:noreply, state}
  end

  def handle_info({:stderr, _os_pir, output}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, output})
    {:noreply, state}
  end

  # API
  def send_input(terminal, input) do
    GenServer.cast(terminal, {:input, input})
  end
end
