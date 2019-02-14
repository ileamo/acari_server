defmodule AcariServer.Zabbix.Server do
  require Logger
  use GenServer, restart: :temporary

  defmodule State do
    defstruct [
      :socket,
      :rest
    ]
  end

  def start_link(sock) do
    Logger.debug("Zabbix server start #{inspect(sock)}")
    GenServer.start_link(__MODULE__, sock)
  end

  ## Callbacks
  @impl true
  def init(sock) do
    Logger.debug("Zabbix server INIT #{inspect(sock)}")
    {:ok, %State{socket: sock, rest: ""}}
  end

  @impl true
  def handle_info({:tcp, socket, packet}, state) do
    packet = state.rest <> packet

    case packet do
      <<"ZBXD", 1, len::little-integer-size(64), json_req::binary-size(len), rest::binary>> ->
        {:ok, request} = Jason.decode(json_req)
        Logger.debug("Zabbix Server: get request: #{inspect(request, pretty: true)}")

        # Response
        {:ok, json} =
          Jason.encode(%{
            response: "success",
            info: "processed: #{length(request["data"])}; failed: 0; total: 1"
          })

        response = <<"ZBXD", 1, byte_size(json)::little-integer-size(64), json::binary>>
        :gen_tcp.send(socket, response)
        {:noreply, %{state | rest: rest}}

      _ ->
        Logger.debug("Zabbix Server: not full packet: #{inspect(packet)}")
        {:noreply, %{state | rest: packet}}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info({:tcp_error, _socket, _reason}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info(mes, state) do
    Logger.warn("Zabbix server: unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  # Client
  def start(sock) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        AcariServer.HsSup,
        child_spec(sock)
      )

    :ok = :gen_tcp.controlling_process(sock, pid)
    {:ok, pid}
  end
end
