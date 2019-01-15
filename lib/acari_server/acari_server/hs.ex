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
         {:ok, %{"id" => id, "link" => link} = request} when is_binary(id) and is_binary(link) <-
           Jason.decode(json),
         {:ok, {ipaddr, port}} <- :ssl.peername(sslsocket),
         Logger.info(
           "Listener: accept connection from #{:inet.ntoa(ipaddr)}:#{port}, id:#{id}, link:#{link}"
         ),
         :ok <- start_tun(request, ipaddr),
         {:ok, pid} <-
           Acari.add_link(id, link, fn
             :connect -> sslsocket
             :restart -> false
           end) do
      :ssl.controlling_process(sslsocket, pid)

      # Re-send ssl messages
      {:messages, list} = Process.info(self(), :messages)

      for {:ssl, _sslsocket, _frame} = mes <- list do
        send(pid, mes)
      end
    else
      res ->
        case res do
          frame when is_binary(frame) ->
            Logger.warn("Bad handshake packet")

          {:error, :not_configured} ->
            :ok

          res ->
            Logger.error("Can't accept connection #{inspect(res)}")
        end

        Process.sleep(1 * 60 * 1000)
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

  # Private
  defp start_tun(%{"id" => id} = request, ipaddr) do
    case Acari.tun_exist?(id) do
      true ->
        :ok

      false ->
        case AcariServer.NodeManager.get_node_by_name(id) do
          nil ->
            new_node(request, ipaddr)
            {:error, :not_configured}

          _ ->
            case Acari.start_tun(id, AcariServer.Master, request["params"]) do
              :ok -> :ok
              {:error, {:already_started, _}} -> :ok
            end
        end
    end
  end

  defp new_node(%{"id" => id} = request, ipaddr) do
    Logger.warn("Connection from unknown node: #{inspect(request)}")

    AcariServer.NewNodeDiscovery.insert_or_update_new_node(%{
      name: id,
      ip_addr: to_string(:inet.ntoa(ipaddr)),
      params: request
    })
  end

  # Client
  def handshake(sock) do
    DynamicSupervisor.start_child(
      AcariServer.HsSup,
      child_spec(sock)
    )
  end
end
