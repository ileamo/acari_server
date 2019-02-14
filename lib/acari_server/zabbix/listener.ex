defmodule AcariServer.Zabbix.Listener do
  use Task, restart: :permanent
  require Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    {:ok, l} = :gen_tcp.listen(7777, [:binary, active: true, packet: 0, reuseaddr: true])
    Logger.debug "Listen 7777"

    accept_loop(l)
  end

  defp accept_loop(l) do
    {:ok, sock} = :gen_tcp.accept(l)
    Logger.info("Accept #{inspect(sock)}")
    {:ok, _pid} = AcariServer.Zabbix.Server.start(sock)
    accept_loop(l)
  end
end
