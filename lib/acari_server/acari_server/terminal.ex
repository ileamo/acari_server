defmodule AcariServer.Terminal do
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  @impl true
  def init(%{output_pid: output_pid, pathname: pathname} = _params) do
    [_, name] = Regex.run(~r|/([^/]+)$|, pathname)
    send(output_pid, {:output, "Подключение к узлу #{name} \r\n"})
    {:ok, shell, _os_pid} = :exec.run('ssh root@10.0.10.102', [:stdin, :stdout, :stderr, :pty])
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
