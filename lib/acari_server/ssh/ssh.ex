defmodule AcariServer.SSH do
  require Logger
  require IEx

  def daemon do
    :ssh.daemon(8989,
      system_dir: 'priv',
      pwdfun: &on_password/4,
      shell: &shell/2,
      id_string: :random
    )
  end

  def on_password(_, _, _, _) do
    true
  end

  def shell(username, peer) do
    spawn_link(__MODULE__, :on_shell, [username])

    # IEx.start([])
  end

  def on_shell(username) do
    :ok = IO.puts("Привет #{username}. Ты попал в Богатку")
    loop(run_state([]))
  end

  def on_connect(username, ip, port, method) do
    Logger.debug(fn ->
      """
      Incoming SSH shell #{inspect(self())} requested for #{username} from #{inspect(ip)}:#{
        inspect(port)
      } using #{inspect(method)}
      """
    end)
  end

  def on_disconnect(username, ip, port) do
    Logger.debug(fn ->
      "Disconnecting SSH shell for #{username} from #{inspect(ip)}:#{inspect(port)}"
    end)
  end

  defp loop(state) do
    self_pid = self()
    counter = state.counter
    prefix = state.prefix

    input = spawn(fn -> io_get(self_pid, prefix, counter) end)
    wait_input(state, input)
  end

  defp wait_input(state, input) do
    receive do
      {:input, ^input, 'exit\n'} ->
        IO.puts("Exiting...")

      {:input, ^input, code} when is_list(code) ->
        code = String.trim(code |> :erlang.list_to_binary)

        IO.puts("Received shell command: #{inspect(code)}")

        loop(%{state | counter: state.counter + 1})

      {:input, ^input, {:error, :interrupted}} ->
        IO.puts("Caught Ctrl+C...")
        loop(%{state | counter: state.counter + 1})

      {:input, ^input, msg} ->
        :ok = Logger.warn("received unknown message: #{inspect(msg)}")
        loop(%{state | counter: state.counter + 1})
    end
  end

  defp run_state(opts) do
    prefix = Keyword.get(opts, :prefix, "shell")

    %{prefix: prefix, counter: 1}
  end

  defp io_get(pid, prefix, counter) do
    prompt = prompt(prefix, counter)
    send(pid, {:input, self(), IO.gets(:stdio, prompt)})
  end

  defp prompt(prefix, counter) do
    prompt =
      "%prefix(%node)%counter>"
      |> String.replace("%counter", to_string(counter))
      |> String.replace("%prefix", to_string(prefix))
      |> String.replace("%node", to_string(node()))

    prompt <> " "
  end
end
