defmodule AcariServer.TCPListener do
  use Task, restart: :permanent

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    {:ok, l} =
      :gen_tcp.listen(
        Application.get_env(:acari_server, AcariServer.TCPListener)[:port],
        reuseaddr: true,
        packet: 2
      )

    accept_loop(l)
  end

  defp accept_loop(l) do
    {:ok, sock} = :gen_tcp.accept(l)
    {:ok, pid} = AcariServer.Hs.handshake(sock, :tcp)
    :gen_tcp.controlling_process(sock, pid)
    accept_loop(l)
  end
end
