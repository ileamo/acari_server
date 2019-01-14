defmodule AcariClient.TunCreator do
  use GenServer
  require Logger

  @test_tuns_num 16
  @links ["BEELINE", "MEGAFON", "MTS", "TELE2"]

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
    for i <- 1..@test_tuns_num do
      :ok = Acari.start_tun(cl_name(i), self())
    end

    Task.start_link(__MODULE__, :test, [])

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
    m1 = Enum.random(@links)
    m2 = Enum.random(@links |> Enum.reject(fn x -> x == m1 end))
    start_sslink(tun_name, m1)
    start_sslink(tun_name, m2)
  end

  defp start_sslink(tun, link) do
    {:ok, request} =
      Jason.encode(%{id: "NSG1700_1812000#{tun |> String.slice(-3, 3)}", link: link})

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

  defp cl_name(i) do
    "cl_#{:io_lib.format("~3..0B", [i])}"
  end

  @impl true
  def handle_call({:start_tun, num}, _from, state) do
    res = Acari.start_tun(cl_name(num), self())
    {:reply, res, state}
  end

  # API
  def start_tun(num) do
    GenServer.call(__MODULE__, {:start_tun, num})
  end

  # TEST
  def test() do
    Process.sleep(Enum.random(5..10) * 1000)
    tun_name = cl_name(Enum.random(1..@test_tuns_num))

    case Enum.random(0..9) do
      0 ->
        for link_name <- @links do
          Task.start_link(__MODULE__, :stop_start_link, [tun_name, link_name])
        end

      _ ->
        link_name = Enum.random(@links)
        Task.start_link(__MODULE__, :stop_start_link, [tun_name, link_name])
    end

    test()
  end

  def stop_start_tun() do
    tun_name = cl_name(Enum.random(1..@test_tuns_num))

    case Acari.stop_tun(tun_name) do
      :ok ->
        Process.sleep(Enum.random(10..120) * 1000)
        start_tun(tun_name)

      _ ->
        nil
    end
  end

  def stop_start_link(tun_name, link_name) do
    case Acari.del_link(tun_name, link_name) do
      :ok ->
        Process.sleep(Enum.random(20..120) * 1000)
        start_sslink(tun_name, link_name)

      _ ->
        nil
    end
  end
end
