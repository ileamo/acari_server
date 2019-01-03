defmodule AcariServer.Master do
  use GenServer
  require Logger

  defmodule State do
    defstruct []
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    {:ok, %State{}}
  end

  @impl true

  def handle_cast({:tun_started, {tun_name, _ifname}}, state) do
    Logger.debug("Master get :tun_started from #{tun_name}")
    Acari.ip_address(:add, tun_name, %{"prefix" => "192.168.1.1/32", "peer" => "192.168.1.2"})
    {:noreply, state}
  end

  def handle_cast({:peer_started, tun_name}, state) do
    Logger.debug("Master get :peer_started from #{tun_name}")

    Acari.send_json_request(tun_name, %{
      method: "ip_address_add",
      params: %{prefix: "192.168.10.1/24", peer: "192.168.10.2"}
    })

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end
end
