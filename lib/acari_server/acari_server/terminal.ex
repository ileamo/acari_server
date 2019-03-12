defmodule AcariServer.Terminal do
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, timeout: 5_000)
  end

  @impl true
  def init(%{output_pid: output_pid, pathname: pathname} = _params) do
    [_, name] = Regex.run(~r|/([^/]+)$|, pathname)
    Process.flag(:trap_exit, true)

    with dstaddr when is_binary(dstaddr) <- AcariServer.Master.get_dstaddr(name),
         send(output_pid, {:output, "Подключение к узлу #{name} \r\n"}),
         {:ok, shell, _os_pid} <-
           :exec.run_link('ssh root@#{dstaddr} -o StrictHostKeyChecking=no', [
             :stdin,
             :stdout,
             :stderr,
             :pty
           ]),
         :exec.send(shell, "stty echo\n") do
      {:ok,
       %{
         output_pid: output_pid,
         shell: shell,
         name: name
       }}
    else
      res ->
        Logger.error("Terminal #{pathname} #{inspect(res)}")
        send(output_pid, {:output, "Не могу подключиться к узлу #{name} \r\n"})

        {:ok,
         %{
           output_pid: output_pid,
           shell: nil,
           name: name
         }}
    end
  end

  @impl true
  def handle_cast({:input, input}, %{shell: nil, output_pid: output_pid} = state) do
    send(output_pid, {:output, input})
    {:noreply, state}
  end

  def handle_cast({:input, input}, %{shell: shell} = state) do
    case :exec.send(shell, input) do
      :ok -> {:noreply, state}
      _ -> {:noreply, %{state | shell: nil}}
    end
  end

  @impl true
  def handle_info({:stdout, _os_pid, output}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, output})
    {:noreply, state}
  end

  def handle_info({:stderr, _os_pid, output}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, output})
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, %{state | shell: nil}}
  end

  def handle_info(message, state) do
    Logger.warn("Terminal #{state[:name]}: Unknown message: #{inspect(message)}")
    {:stop, :shutdown, state}
  end

  # API
  def send_input(terminal, input) do
    GenServer.cast(terminal, {:input, input})
  end
end
