defmodule AcariServer.Master do
  use GenServer
  require Logger
  require Acari.Const, as: Const
  alias AcariServerWeb.Endpoint

  defmodule State do
    defstruct [
      :tuns
    ]
  end

  defmodule TunState do
    defstruct [
      :node,
      inventory: "Нет данных",
      telemetry: "Нет данных",
      sslinks: %{}
    ]
  end

  defmodule SSlinkState do
    defstruct up: false,
              down_count: 0,
              tm_start: 0,
              tm_down: 0,
              tm_down_start: 0
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    tuns = :ets.new(:tuns, [:set, :protected, :named_table])

    {:ok, %State{tuns: tuns}}
  end

  @impl true

  def handle_cast({:tun_started, %{tun_name: tun_name} = tun_state}, state) do
    Logger.debug("Master get :tun_started from #{tun_name}, tun_state = #{inspect(tun_state)}")
    params = %{"ifname" => tun_state.ifname}
    peer_params = tun_state.peer_params
    :ets.insert(:tuns, {tun_name, params, peer_params, %TunState{}})
    exec_local_script(tun_name)
    {:noreply, state}
  end

  def handle_cast({:peer_started, tun_name}, state) do
    Logger.debug("Master get :peer_started from #{tun_name}")
    # send_config(tun_name)
    get_inventory(tun_name)

    {:noreply, state}
  end

  def handle_cast({:sslink_opened, tun_name, sslink_name, _num}, state) do
    set_sslink_up(tun_name, sslink_name, true)
    broadcast_link_event()
    {:noreply, state}
  end

  def handle_cast({:sslink_closed, tun_name, sslink_name, _num}, state) do
    set_sslink_up(tun_name, sslink_name, false)
    broadcast_link_event()
    {:noreply, state}
  end

  def handle_cast({:master_mes, tun_name, json}, state) do
    with {:ok, %{"method" => method, "params" => params}} <- Jason.decode(json) do
      exec_server_method(state, tun_name, method, params)
    else
      res ->
        Logger.error("Bad master_mes from #{tun_name}: #{inspect(res)}")
    end

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_server_method(state, tun_name, "put.data", %{"id" => "inventory", "data" => data}) do
    Logger.info("Get inventory data #{data}")
    set_inventory(tun_name, data)
    state
  end

  defp exec_server_method(state, tun_name, "put.data", %{"id" => "telemetry", "data" => data}) do
    Logger.info("Get telemetry data #{data}")
    set_telemetry(tun_name, data)
    state
  end

  defp exec_server_method(state, tun_name, "get.conf", %{"id" => id}) do
    Logger.info("Get config request #{id}")
    send_config(tun_name)
    state
  end

  defp exec_server_method(state, _tun_name, method, _params) do
    Logger.error("Bad message method: #{method}")
    state
  end

  defp set_sslink_up(tun_name, sslink_name, link_state) do
    with tun_state = %TunState{} <- :ets.lookup_element(:tuns, tun_name, 4),
         tun_state <-
           tun_state
           |> update_in([Access.key!(:sslinks), sslink_name], fn
             nil ->
               tm = :erlang.system_time(:second)

               %SSlinkState{tm_start: tm, tm_down_start: tm, tm_down: 0}
               |> update_link_state(link_state)

             sslink_state ->
               sslink_state |> update_link_state(link_state)
           end) do
             AcariServer.Zabbix.Sender.zbx_send(tun_name, "alive[#{sslink_name}]", (if link_state, do: 1, else: 0))
      :ets.update_element(
        :tuns,
        tun_name,
        {4, tun_state}
      )
    else
      res -> Logger.error("Can't set sslink state: #{inspect(res)}")
    end
  end

  defp update_link_state(sslink_state, link_state) do
    case link_state do
      true ->
        %SSlinkState{
          sslink_state
          | up: link_state,
            tm_down:
              sslink_state.tm_down + (:erlang.system_time(:second) - sslink_state.tm_down_start)
        }

      _ ->
        %SSlinkState{
          sslink_state
          | up: link_state,
            down_count: sslink_state.down_count + 1,
            tm_down_start: :erlang.system_time(:second)
        }
    end
  end

  defp set_inventory(tun_name, inventory) do
    inventory = "#{AcariServer.get_local_time()}\n#{inventory}"

    with tun_state = %TunState{} <- :ets.lookup_element(:tuns, tun_name, 4),
         tun_state <- %TunState{
           tun_state
           | inventory: inventory
         } do
      :ets.update_element(
        :tuns,
        tun_name,
        {4, tun_state}
      )

      AcariServer.NodeMonitorAgent.event(tun_name, "inventory", inventory)
    else
      res -> Logger.error("Can't set inventory: #{inspect(res)}")
    end
  end

  defp set_telemetry(tun_name, telemetry) do
    telemetry = "#{AcariServer.get_local_time()}\n#{telemetry}"

    with tun_state = %TunState{} <- :ets.lookup_element(:tuns, tun_name, 4),
         tun_state <- %TunState{
           tun_state
           | telemetry: telemetry
         } do
      :ets.update_element(
        :tuns,
        tun_name,
        {4, tun_state}
      )

      AcariServer.NodeMonitorAgent.event(tun_name, "telemetry", telemetry)
    else
      res -> Logger.error("Can't set sslink state: #{inspect(res)}")
    end
  end

  defp exec_local_script(tun_name) do
    script = AcariServer.SFX.get_script(tun_name, :local, get_tun_params(tun_name))
    Acari.exec_sh(script)
  end

  def send_config(tun_name) do
    request = %{
      method: "put.conf",
      params: %{
        script: 0
      }
    }

    script = AcariServer.SFX.get_script(tun_name, :remote, get_tun_params(tun_name))
    Acari.TunMan.send_master_mes_plus(tun_name, request, [script])
  end

  def get_inventory(tun_name) do
    {:ok, json} =
      Jason.encode(%{
        method: "get_exec_sh",
        params: %{
          id: "inventory",
          script: AcariServer.SFX.get_script(tun_name, :inventory, get_tun_params(tun_name))
        }
      })

    Acari.TunMan.send_tun_com(tun_name, Const.master_mes(), json)
  end

  def get_telemetry(tun_name) do
    {:ok, json} =
      Jason.encode(%{
        method: "get_exec_sh",
        params: %{
          id: "telemetry",
          script: AcariServer.SFX.get_script(tun_name, :telemetry, get_tun_params(tun_name))
        }
      })

    Acari.TunMan.send_tun_com(tun_name, Const.master_mes(), json)
  end

  defp get_tun_params(tun_name) do
    with [{_, params, peer_params, _}] <- :ets.lookup(:tuns, tun_name) do
      peer_params
      |> Enum.map(fn {k, v} -> {"peer_" <> k, v} end)
      |> Enum.concat(Map.to_list(params))
      |> List.insert_at(0, {"id", tun_name})
      |> Enum.into(%{})
    end
  end

  # API
  #  def get_tuns_state() do
  #    :ets.match(:tuns, {:"$1", :_, :_, :_})
  #    |> Enum.map(fn [name] -> [name, Acari.get_all_links(name)] end)
  #  end

  def get_dstaddr(tun_name) do
    with %{"ifname" => ifname} <- get_tun_params(tun_name),
         {:ok, list} <- :inet.getifaddrs(),
         {_, addr_list} <-
           list |> Enum.find(fn {name, _} -> name == to_charlist(ifname) end),
         {:ok, dstaddr} <- addr_list |> Keyword.fetch(:dstaddr),
         dstaddr when is_list(dstaddr) <- :inet.ntoa(dstaddr) do
      to_string(dstaddr)
    else
      _ -> nil
    end
  end

  def get_tuns_state() do
    :ets.tab2list(:tuns)
  end

  defp broadcast_link_event() do
    AcariServer.NodeNumbersAgent.update()

    mes_html = Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "messages.html", [])

    statistics_html =
      Phoenix.View.render_to_string(AcariServerWeb.PageView, "statistics.html", [])

    progress_html = Phoenix.View.render_to_string(AcariServerWeb.PageView, "progress.html", [])

    Endpoint.broadcast!("room:lobby", "link_event", %{
      num_of_mes: Acari.LinkEventAgent.get_length(),
      messages: mes_html,
      statistics: statistics_html,
      progress: progress_html
    })
  end

  def get_nodes_num() do
    case :ets.info(:tuns, :size) do
      n when is_number(n) -> n
      _ -> 0
    end
  end
end
