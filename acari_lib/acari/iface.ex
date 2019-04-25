defmodule Acari.Iface do
  require Logger
  use GenServer, restart: :temporary

  @moduledoc """
  For IPv4 addresses, beam needs to have privileges to configure interfaces.
  To add cap_net_admin capabilities:
  lubuntu:
  sudo setcap cap_net_admin=ep /usr/lib/erlang/erts-10.1/bin/beam.smp cap_net_admin=ep /bin/ip
  gentoo:
  sudo setcap cap_net_admin=ep /usr/lib64/erlang/erts-10.1.1/bin/beam.smp cap_net_admin=ep /bin/ip
  production:
  sudo setcap cap_net_admin=ep ./erts-10.1.1/bin/beam.smp cap_net_admin=ep /bin/ip
  """
  defmodule State do
    defstruct [
      :tun_name,
      :ifsocket,
      :ifname,
      :ifsnd_pid,
      :sslink_snd_pid
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  ## Callbacks
  @impl true
  def init(%{tun_name: tun_name} = _params) do
    {:ok, ifsocket} = :tuncer.create(<<>>, [:tun, :no_pi, active: true])
    :tuncer.persist(ifsocket, false)
    ifname = :tuncer.devname(ifsocket)
    :ok = if_up(ifname)

    {:ok, ifsnd_pid} =
      Acari.IfaceSnd.start_link(%{tun_name: tun_name, ifsocket: ifsocket, ifname: ifname})

    if Application.get_env(:acari, :server) do
      Phoenix.PubSub.subscribe(AcariServer.PubSub, "rcv:#{tun_name}")
    end

    Logger.info("#{tun_name}: iface #{ifname}: created")

    state = %State{
      tun_name: tun_name,
      ifsocket: ifsocket,
      ifname: ifname,
      ifsnd_pid: ifsnd_pid
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:set_sslink_snd_pid, sslink_snd_pid}, state) do
    {:noreply, %State{state | sslink_snd_pid: sslink_snd_pid}}
  end

  @impl true
  def handle_call(:get_if_info, _from, %{ifname: ifname, ifsnd_pid: ifsnd_pid} = state) do
    {:reply, {ifname, ifsnd_pid}, state}
  end

  @impl true
  def handle_info(
        {:tuntap, _pid, packet},
        state = %{sslink_snd_pid: sslink_snd_pid}
      )
      when is_pid(sslink_snd_pid) do
    case Process.alive?(sslink_snd_pid) do
      true ->
        Acari.SSLinkSnd.send(sslink_snd_pid, packet)
        {:noreply, state}

      _ ->
        redirect(state, packet)
        {:noreply, %State{state | sslink_snd_pid: nil}}
    end
  end

  def handle_info({:tuntap, _pid, packet}, state) do
    redirect(state, packet)
    {:noreply, state}
  end

  def handle_info({:tuntap_error, _pid, reason}, state) do
    Logger.error("#{state.tun_name}: iface #{state.ifname}: #{inspect(reason)}")
    # GenServer.cast(pid, :terminate)
    {:stop, :shutdown, state}
  end

  def handle_info({:redirect, packet, used_nodes}, %{sslink_snd_pid: sslink_snd_pid} = state) do
    if is_pid(sslink_snd_pid) && Process.alive?(sslink_snd_pid) do
      Acari.SSLinkSnd.send(sslink_snd_pid, packet)
    else
      redirect(state, packet, used_nodes)
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("#{state.tun_name}: iface #{state.ifname}: unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{ifsocket: ifsocket}) do
    :tuncer.destroy(ifsocket)
  end

  # client
  def set_sslink_snd_pid(iface_pid, sslink_snd_pid) do
    GenServer.cast(iface_pid, {:set_sslink_snd_pid, sslink_snd_pid})
  end

  def get_if_info(iface_pid) do
    GenServer.call(iface_pid, :get_if_info, 60 * 1000)
  end

  def if_up(ifname), do: if_set_admstate(ifname, "up")
  def if_down(ifname), do: if_set_admstate(ifname, "down")

  defp if_set_admstate(ifname, admstate) do
    {_, 0} = System.cmd("ip", ["link", "set", ifname, admstate], stderr_to_stdout: true)
    :ok
  end

  defp redirect(state, packet, used_nodes \\ []) do
    case Node.list() -- used_nodes do
      [node | _] ->
        Phoenix.PubSub.direct_broadcast_from(
          node,
          AcariServer.PubSub,
          self(),
          "rcv:#{state.tun_name}",
          {:redirect, packet, [node() | used_nodes]}
        )

      _ ->
        nil
    end
  end
end

defmodule Acari.IfaceSnd do
  use GenServer
  require Logger

  import Acari.Iface, only: [if_up: 1, if_down: 1]

  defmodule State do
    defstruct [
      :tun_name,
      :ifsocket,
      :ifname,
      main_server: true
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  ## Callbacks
  @impl true
  def init(%{tun_name: tun_name, ifsocket: ifsocket, ifname: ifname}) do
    if Application.get_env(:acari, :server) do
      Phoenix.PubSub.subscribe(AcariServer.PubSub, "snd:#{tun_name}")
    end

    {:ok, %State{tun_name: tun_name, ifsocket: ifsocket, ifname: ifname}}
  end

  @impl true
  def handle_cast({:send, packet}, state = %{main_server: node, ifsocket: ifsocket}) do
    case node do
      true ->
        :tuncer.send(ifsocket, packet)

      node ->
        Phoenix.PubSub.direct_broadcast_from(
          node,
          AcariServer.PubSub,
          self(),
          "snd:#{state.tun_name}",
          {:send, packet}
        )
    end

    {:noreply, state}
  end

  if Application.get_env(:acari, :server) do
    @impl true
    def handle_info({:send, packet}, state = %{ifsocket: ifsocket}) do
      :tuncer.send(ifsocket, packet)
      {:noreply, state}
    end

    def handle_info({:main_server, node}, %{ifname: ifname} = state) do
      Logger.info("#{state.tun_name}: Set main server as #{node}")

      node =
        if node == node() do
          if_up(ifname)
          true
        else
          if_down(ifname)
          node
        end

      {:noreply, %State{state | main_server: node}}
    end

    def handle_info(msg, state) do
      Logger.error("#{state.tun_name}: IfaceSnd: unexpected message: #{inspect(msg)}")
      {:noreply, state}
    end
  end

  # Client

  def send(ifsnd_pid, packet) do
    GenServer.cast(ifsnd_pid, {:send, packet})
  end
end
