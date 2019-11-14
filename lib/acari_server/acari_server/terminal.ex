defmodule AcariServer.Terminal do
  use GenServer, restart: :temporary
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, timeout: 5_000)
  end

  @impl true
  def init(%{output_pid: output_pid, tun_name: name, command: command} = params) do
    Process.flag(:trap_exit, true)

    with send(output_pid, {:output, "Подключение к #{name} \r\n"}),
         {:ok, shell, _os_pid} <-
           :exec.run_link(command, [
             :stdin,
             :stdout,
             :stderr,
             :pty
           ]),
         :exec.send(shell, params[:init_send] || "") do
      {:ok,
       %{
         output_pid: output_pid,
         shell: shell,
         name: name
       }}
    else
      res ->
        Logger.error("Terminal #{name} #{inspect(res)}")
        send(output_pid, {:output, "Не могу подключиться к #{name} \r\n"})

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

  def start_child(node, params) do
    DynamicSupervisor.start_child(
      {AcariServer.TermSup, node},
      child_spec(params)
    )
  end
end
