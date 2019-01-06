defmodule AcariClient.TunCreator do
  use GenServer
  require Logger

  defmodule State do
    defstruct [
      :tun_name,
      :ifname
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    for i <- 1..3 do
      :ok = Acari.start_tun("cl_#{:io_lib.format("~3..0B", [i])}", self())
    end

    {:ok, %State{}}
  end

  @impl true
  def handle_cast({:tun_started, {tun_name, ifname}}, state) do
    Logger.debug("Acari client receive :tun_started from #{tun_name}:#{ifname}")
    restart_tunnel(tun_name)
    {:noreply, %State{state | tun_name: tun_name, ifname: ifname}}
  end

  def handle_cast({:peer_started, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:tun_mes, tun_name, json}, state) do
    with {:ok, %{"method" => method, "params" => params}} <- Jason.decode(json) do
      exec_client_method(state, method, params)
    else
      res ->
        Logger.error("Bad tun_mes from #{tun_name}: #{inspect(res)}")
    end

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Client get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_client_method(state, "exec_sh", %{"script" => script}) do
    Acari.exec_sh(script)
    state
  end

  defp exec_client_method(state, method, _params) do
    Logger.error("Bad message method: #{method}")
    state
  end

  defp restart_tunnel(tun_name) do
    # start link M1
    start_sslink(tun_name, "BEELINE")
    start_sslink(tun_name, "MEGAFON")
  end

  defp start_sslink(tun, link) do
    {:ok, request} =
      Jason.encode(%{id: "nsg1700_1812000#{tun |> String.slice(-3, 3)}", link: link})

    {:ok, _pid} =
      Acari.add_link(tun, link, fn
        :connect ->
          connect(%{host: "localhost", port: 7000}, request)

        :restart ->
          true
      end)
  end

  defp connect(%{host: host, port: port} = params, request) do
    case :ssl.connect(to_charlist(host), port, [packet: 2], 5000) do
      {:ok, sslsocket} ->
        :ssl.send(sslsocket, <<1::1, 0::15>> <> request)
        sslsocket

      {:error, reason} ->
        Logger.warn("Can't connect #{host}:#{port}: #{inspect(reason)}")
        Process.sleep(10_000)
        connect(params, request)
    end
  end
end
