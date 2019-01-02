defmodule AcariServer.Hs do
  require Logger
  use GenServer, restart: :temporary

  def start_link(sock) do
    GenServer.start_link(__MODULE__, sock)
  end

  ## Callbacks
  @impl true
  def init(sock) do
    :ssl.controlling_process(sock, self())
    {:ok, sock, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, sock) do
    {:ok, sslsock} = :ssl.handshake(sock)
    {:noreply, %{sslsocket: sslsock}}
  end

  @impl true
  def handle_info({:ssl, sslsocket, frame}, state) do
    with <<1::1, _val::15, json::binary>> <- :erlang.list_to_binary(frame),
         {:ok, %{"id" => id, "link" => link}} when is_binary(id) and is_binary(link) <-
           Jason.decode(json),
         {:ok, {ipaddr, port}} = :ssl.peername(sslsocket),
         Logger.info(
           "Listener: accept connection from #{:inet.ntoa(ipaddr)}:#{port}, id:#{id}, link:#{link}"
         ),
         :ok <-
           (case Acari.start_tun(id, AcariServer.Master) do
              :ok -> :ok
              {:error, {:already_started, _}} -> :ok
            end),
         {:ok, pid} <-
           Acari.add_link(id, link, fn
             :connect -> sslsocket
             :restart -> false
           end) do
      :ssl.controlling_process(sslsocket, pid)
    else
      frame when is_binary(frame) ->
        Logger.warn("Bad handshake packet")

      res ->
        Logger.error("Can't accept connection #{inspect(res)}")
    end

    {:stop, :shutdown, state}
  end

  def handle_info({:ssl_closed, _sslsocket}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info({:ssl_error, _sslsocket, _reason}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info(msg, state) do
    Logger.warn("SSL: unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Client
  def handshake(sock) do
    DynamicSupervisor.start_child(
      AcariServer.HsSup,
      child_spec(sock)
    )
  end
end
