defmodule AcariServer.Zabbix.Sender do
  require Logger
  use GenServer

  defmodule State do
    defstruct [
      :port
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    Process.flag(:trap_exit, true)

    with {:ok, port, _os_pid} <- run_zbx_sender() do
      {:ok, %State{port: port}}
    else
      res ->
        Logger.error("Can't run acari_zbx: #{inspect(res)}")
        {:ok, %State{port: nil}}
    end
  end

  @impl true
  def handle_cast({:send, sensor}, %{port: port} = state) do
    case :exec.send(port, sensor) do
      :ok -> {:noreply, state}
      _ -> {:noreply, %{state | port: nil}}
    end
  end

  @impl true
  def handle_info({:stdout, _os_pid, output}, state) do
    Logger.debug("zbx_sender stdout: #{output}")
    {:noreply, state}
  end

  def handle_info({:stderr, _os_pid, output}, state) do
    Logger.debug("zbx_sender stderr: #{output}")
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error("zbx_sender exited: #{inspect(reason)}")
    Process.sleep(10_000)

    with {:ok, port, _os_pid} <- run_zbx_sender() do
      {:noreply, %State{state | port: port}}
    else
      res ->
        Logger.error("Can't run acari_zbx: #{inspect(res)}")
        {:noreply, %State{state | port: nil}}
    end
  end

  def handle_info(mes, state) do
    Logger.warn("Zabbix sender: unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp run_zbx_sender() do
    :exec.run_link(
      'priv/usr/acari_zbx.lua -d -zhttp://zabbix-web-nginx-pgsql/ -uAdmin -pzabbix -gacari_clients -tacari_client -macari_master',
      [
        :stdin,
        :stdout,
        :stderr,
        :pty
      ]
    )
  end

  # API
  def zbx_send(host, key, value) do
    {:ok, json} = Jason.encode(%{host: host, key: key, value: value})
    GenServer.cast(__MODULE__, {:send, json <> "\n"})
  end

  def zbx_send_master(key, value) do
    Task.start(fn ->
      case System.cmd("zabbix_sender", [
             "-zzabbix-server-pgsql",
             "-p50051",
             "-sacari_master",
             "-k",
             key,
             "-o",
             value
           ]) do
        {res, 0} -> Logger.debug("zabbix_sender: #{res}")
        {err, code} -> Logger.warn("zabbix_sender exits with code #{code}, output: #{err}")
      end
    end)
  end
end
