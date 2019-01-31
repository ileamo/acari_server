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
  def handle_cast({:input, id}, %{tun_name: tun_name} = state) do
    IO.inspect({tun_name, id}, label: "*** NodeMonitor ***")
    AcariServer.Master.get_inventory(tun_name)
    put_data(self(), id, "*** new #{id} ***")
    {:noreply, state}
  end

  def handle_cast({:output, id, data}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, id, data})
    {:noreply, state}
  end

  # API
  def get_input(node_monitor, input) do
    GenServer.cast(node_monitor, {:input, input})
  end

  def put_data(node_monitor, id, data) do
    GenServer.cast(node_monitor, {:output, id, data})
  end
end
