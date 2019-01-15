defmodule AcariServer.Master do
  use GenServer
  require Logger

  defmodule State do
    defstruct [
      :tuns
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    tuns = :ets.new(:tuns, [:set, :protected, :named_table])

    {:ok, %State{tuns: tuns}}
  end

  @impl true

  def handle_cast({:tun_started, %{tun_name: tun_name} = tun_state}, state) do
    Logger.debug("Master get :tun_started from #{tun_name}, tun_state = #{inspect(tun_state)}")
    :ets.insert(:tuns, {tun_name, %{"ifname" => tun_state.ifname}, tun_state.peer_params})
    # Acari.ip_address(:add, tun_name, %{"prefix" => "192.168.1.1/32", "peer" => "192.168.1.2"})
    {:noreply, state}
  end

  def handle_cast({:peer_started, tun_name}, state) do
    Logger.debug("Master get :peer_started from #{tun_name}")
    [{_, params, peer_params}] = :ets.lookup(:tuns, tun_name)
    exec_remote_script(tun_name, params, peer_params)

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_remote_script(tun_name, params, peer_params) do
    IO.inspect({tun_name, params, peer_params}, label: "EXEC_REMOTE_SCRIPT")
  end
end
