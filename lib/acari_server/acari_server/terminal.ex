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
         name: name,
         utf8_tail: nil
       }}
    else
      res ->
        Logger.error("Terminal #{name} #{inspect(res)}")
        send(output_pid, {:output, "Не могу подключиться к #{name} \r\n"})

        {:ok,
         %{
           output_pid: output_pid,
           shell: nil,
           name: name,
           utf8_tail: nil
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
      :ok ->
        {:noreply, state}

      _ ->
        :exec.stop(shell)
        {:noreply, %{state | shell: nil}}
    end
  end

  @impl true
  def handle_info({:stdout, _os_pid, output}, state) do
    send_utf8(output, state)
  end

  def handle_info({:stderr, _os_pid, output}, state) do
    send_utf8(output, state)
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    :exec.stop(state.shell)

    {:noreply, %{state | shell: nil}}
  end

  def handle_info(message, state) do
    Logger.warn("Terminal #{state[:name]}: Unknown message: #{inspect(message)}")
    {:stop, :shutdown, state}
  end

  defp send_utf8(output, %{output_pid: output_pid, utf8_tail: tail} = state) do
    {output, last} = utf8_slice(tail, output)

    send(output_pid, {:output, output})
    {:noreply, %{state | utf8_tail: last}}
  end

  defp utf8_slice(tail, output) do
    output = (tail && tail <> output) || output
    last = output |> String.last()

    case last |> String.valid?() do
      true -> {output, nil}
      _ -> {output |> String.slice(0..-2), last}
    end
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
