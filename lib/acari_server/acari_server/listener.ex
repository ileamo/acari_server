defmodule AcariServer.Listener do
  use Task, restart: :permanent

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    {:ok, l} =
      :ssl.listen(
        Application.get_env(:acari_server, AcariServer.Listener)[:port],
        certfile: Application.get_env(:acari_server, AcariServer.Listener)[:certfile],
        keyfile: Application.get_env(:acari_server, AcariServer.Listener)[:keyfile],
        versions: [:"tlsv1.3", :"tlsv1.2"],
        reuseaddr: true,
        packet: 2
      )

    accept_loop(l)
  end

  defp accept_loop(l) do
    {:ok, sock} = :ssl.transport_accept(l)
    {:ok, _pid} = AcariServer.Hs.handshake(sock, :tls)
    accept_loop(l)
  end
end
