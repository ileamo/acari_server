defmodule Acari.SSLink do
  use GenServer, restart: :temporary
  require Logger
  require Acari.Const, as: Const
  alias Acari.Iface
  alias Acari.TunMan

  defmodule State do
    defstruct [
      :name,
      :connector,
      :pid,
      :tun_name,
      :tun_man_pid,
      :snd_pid,
      :iface_pid,
      :ifsnd_pid,
      :sslsocket,
      :latency
    ]
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  ## Callbacks
  @impl true
  def init(%{name: name, tun_man_pid: tun_man_pid, iface_pid: iface_pid} = state)
      when is_binary(name) and is_pid(tun_man_pid) and is_pid(iface_pid) do
    {:ok, %State{} |> Map.merge(state), {:continue, :init}}
  end

  @impl true
  def handle_continue(
        :init,
        %{name: name, connector: connector, tun_man_pid: tun_man_pid, iface_pid: iface_pid} =
          state
      ) do
    sslsocket = connector.(:connect)

    {:ok, snd_pid} =
      Acari.SSLinkSnd.start_link(%{sslsocket: sslsocket, name: name, tun_name: state.tun_name})

    {_, ifsnd_pid} = Iface.get_if_info(iface_pid)
    TunMan.set_sslink_snd_pid(tun_man_pid, name, snd_pid)
    schedule_ping()

    {:noreply,
     %{state | pid: self(), sslsocket: sslsocket, snd_pid: snd_pid, ifsnd_pid: ifsnd_pid}}
  end

  @impl true
  def handle_cast(:terminate, state) do
    {:stop, :shutdown, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:ssl, _sslsocket, frame}, %{ifsnd_pid: ifsnd_pid} = state) do
    state =
      case parse(:erlang.list_to_binary(frame)) do
        {:int, com, data} ->
          exec_link_command(state, com, data)

        {:ext, com, data} ->
          TunMan.recv_tun_com(state.tun_man_pid, com, data)
          state

        packet ->
          Acari.IfaceSnd.send(ifsnd_pid, packet)
          state
      end

    {:noreply, state}
  end

  def handle_info({:ssl_closed, _sslsocket}, %{name: name, tun_name: tun_name} = state) do
    Logger.info("#{tun_name}: #{name}: Closed")
    {:stop, :shutdown, state}
  end

  def handle_info({:ssl_error, _sslsocket, _reason}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info(:ping, state) do
    send_link_command(
      state,
      Const.echo_request(),
      <<:erlang.system_time(:microsecond)::64>>
    )

    # Reschedule once more
    schedule_ping()
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("SSL: unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Client

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Private

  defp parse(frame) do
    <<com::1, scope::1, val::14, packet::binary>> = frame

    case com do
      0 ->
        packet

      1 ->
        case scope do
          0 -> {:ext, val, packet}
          1 -> {:int, val, packet}
        end
    end
  end

  defp send_link_command(state, com, payload) do
    Acari.SSLinkSnd.send(state.snd_pid, <<Const.link_mask()::2, com::14>>, payload)
  end

  defp exec_link_command(state, com, data) do
    # Logger.debug("get int command: #{inspect(%{com: com, data: data})}")

    case com do
      Const.echo_reply() ->
        <<n::64>> = data
        latency = :erlang.system_time(:microsecond) - n
        TunMan.set_sslink_params(state.tun_man_pid, state.name, %{latency: latency})
        %State{state | latency: latency}

      Const.echo_request() ->
        send_link_command(state, Const.echo_reply(), data)
        state

      _ ->
        Logger.warn(
          "#{state.tun_name}: #{state.name}: unexpected int command: #{
            inspect(%{com: com, data: data})
          }"
        )

        state
    end
  end

  defp schedule_ping() do
    Process.send_after(self(), :ping, Enum.random(4000..6000))
  end
end

defmodule Acari.SSLinkSnd do
  require Logger
  use GenServer, restart: :temporary

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  ## Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:send, packet}, state = %{sslsocket: sslsocket}) do
    case :ssl.send(sslsocket, packet) do
      :ok ->
        {:noreply, state}

      {:error, reason} ->
        Logger.warn(
          "#{state.tun_name}: #{state.name}: Can't send to SSL socket: #{inspect(reason)}"
        )

        {:stop, :shutdown}
    end
  end

  # Client

  def send(sslink_snd_pid, header \\ <<0::16>>, packet) do
    frame = header <> packet
    GenServer.cast(sslink_snd_pid, {:send, frame})
  end
end
