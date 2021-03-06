defmodule AcariServer.ServerMonitor do
  use GenServer
  require Logger
  alias AcariServer.Mnesia

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    AcariServer.Mnesia.init()
    connect_all_nodes()
    :net_kernel.monitor_nodes(true)
    {:ok, %{}}
  end

  def connect_all_nodes() do
    AcariServer.ServerManager.list_servers()
    |> Enum.each(fn %{system_name: node} -> Node.connect(node |> String.to_atom()) end)
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.error("Server monitor: Node #{node} is DOWN")
    Mnesia.update_servers_list()
    Mnesia.delete_server(node)

    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    Logger.info("Server monitor: Node #{node} is UP")
    Mnesia.update_servers_list()

    {:noreply, state}
  end

  def handle_info(mes, state) do
    Logger.warn("Server monitor: Unexpected info message: #{inspect(mes)}")
    {:noreply, state}
  end
end
