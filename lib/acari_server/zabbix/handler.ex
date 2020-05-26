defmodule AcariServer.Zabbix.Handler do
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:handle, host, "errormsg." <> port, value}, state) do
    AcariServer.Mnesia.update_tun_state(host, :errormsg, %{
      port => %{msg: value, timestamp: :os.system_time(:second)}
    })

    {:noreply, state}
  end

  def handle_cast({:handle, _host, key, _value}, state) do
    Logger.warn("Zabbix handler: Unknown key #{key}")
    {:noreply, state}
  end

  def handle(host, key, value) do
    GenServer.cast(__MODULE__, {:handle, host, key, value})
  end
end
