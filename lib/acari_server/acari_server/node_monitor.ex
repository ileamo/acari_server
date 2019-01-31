defmodule AcariServer.NodeMonitor do
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  @impl true
  def init(%{output_pid: output_pid, pathname: pathname} = _params) do
    [_, name] = Regex.run(~r|/([^/]+)$|, pathname)

    {:ok,
     %{
       tun_name: name,
       output_pid: output_pid
     }}
  end

  @impl true
  def handle_cast({:input, input}, %{tun_name: tun_name} = state) do
    IO.inspect({tun_name, input}, label: "*** NodeMonitor ***")
    {:noreply, state}
  end

  # API
  def send_input(node_monitor, input) do
    IO.inspect({node_monitor, input}, label: "*** NodeMonitor send_input ***")

    GenServer.cast(node_monitor, {:input, input})
  end
end
