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
    {:ok, cwd} = File.cwd()

    # {:ok, port, _os_pid} =
    #           :exec.run_link('ssh root@#{dstaddr} -o StrictHostKeyChecking=no', [
    #             :stdin,
    #             :stdout,
    #             :stderr,
    #             :pty
    #           ])

    port =
      Port.open({:spawn_executable, cwd <> "/priv/usr/uizbxd.lua"}, [
        :binary,
        :use_stdio,
        :stderr_to_stdout,
        cd: cwd <> "/priv/usr/",
        args: ["-d", "-zhttp://10.0.10.10:10080/", "-uAdmin", "-pzabbix", "-gacari"]
      ])

    {:ok, %State{port: port}}
  end

  @impl true
  def handle_info(mes, state) do
    Logger.warn("Zabbix sender: unknown message: #{inspect(mes)}")
    {:noreply, state}
  end
end
