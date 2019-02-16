defmodule AcariServer.Zabbix.Server do
  require Logger
  use GenServer, restart: :temporary

  defmodule State do
    defstruct [
      :socket,
      :rest
    ]
  end

  def start_link(listen_sock) do
    GenServer.start_link(__MODULE__, listen_sock)
  end

  ## Callbacks
  @impl true
  def init(listen_sock) do
    {:ok, sock} = :gen_tcp.accept(listen_sock)
    {:ok, %State{socket: sock, rest: ""}}
  end

  @impl true
  def handle_info({:tcp, socket, packet}, state) do
    packet = state.rest <> packet

    case packet do
      <<"ZBXD", 1, len::little-integer-size(64), json_req::binary-size(len), rest::binary>> ->
        {:ok, request} = Jason.decode(json_req)

        {:ok, json} = handle_zbx_request(request)

        response = <<"ZBXD", 1, byte_size(json)::little-integer-size(64), json::binary>>
        :gen_tcp.send(socket, response)
        {:noreply, %{state | rest: rest}}

      _ ->
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

  # Private
  defp handle_zbx_request(%{"request" => "sender data", "data" => data}) when is_list(data) do
    num =
      data
      |> Enum.reduce(0, fn
        %{"host" => host, "key" => key, "value" => value}, acc ->
          AcariServer.Zabbix.LastDataAgent.put(host, key, value)
          acc + 1

        _, acc ->
          acc
      end)

    Jason.encode(%{
      response: "success",
      info: "processed: #{num}; failed: 0; total: #{num}"
    })
  end

  defp handle_zbx_request(request) do
    Jason.encode(%{
      response: "error",
      info: "Bad request #{inspect(request)}"
    })
  end

  # Client
  def start(listen_sock) do
    DynamicSupervisor.start_child(
      AcariServer.Zabbix.SerSup,
      child_spec(listen_sock)
    )
  end
end
