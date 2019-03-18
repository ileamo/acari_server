defmodule AcariServer.Zabbix.Sender do
  require Logger
  use GenServer

  defmodule State do
    defstruct [
      :port
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    Process.flag(:trap_exit, true)

    with {:ok, port, _os_pid} <- run_zbx_sender() do
      {:ok, %State{port: port}}
    else
      res ->
        Logger.error("Can't run uizbxd: #{inspect(res)}")
        {:ok, %State{port: nil}}
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
        Logger.error("Can't run uizbxd: #{inspect(res)}")
        {:noreply, %State{state | port: nil}}
    end
  end

  def handle_info(mes, state) do
    Logger.warn("Zabbix sender: unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp run_zbx_sender() do
    :exec.run_link(
      'priv/usr/uizbxd.lua -zhttp://10.0.10.10:10080/ -uAdmin -pzabbix -gacari',
      [
        :stdin,
        :stdout,
        :stderr,
        :pty
      ]
    )
  end
end
