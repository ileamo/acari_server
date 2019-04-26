defmodule AcariServer.Zabbix.Listener do
  use Task, restart: :permanent
  require Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    zbx_listen_port = Application.get_env(:acari_server, :zabbix)[:zbx_listen_port] || 50051

    {:ok, l} =
      :gen_tcp.listen(zbx_listen_port, [:binary, active: true, packet: 0, reuseaddr: true])

    accept_loop(l)
  end

  defp accept_loop(l) do
    {:ok, _pid} = AcariServer.Zabbix.Server.start(l)
    accept_loop(l)
  end
end
