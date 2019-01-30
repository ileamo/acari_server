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
      sslinks: %{}
    ]
  end

  defmodule SSlinkState do
    defstruct up: false
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
    exec_remote_script(tun_name)

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

  def handle_cast({:tun_mes, tun_name, json}, state) do
    with {:ok, %{"method" => method, "params" => params}} <- Jason.decode(json) do
      exec_client_method(state, tun_name, method, params)
    else
      res ->
        Logger.error("Bad tun_mes from #{tun_name}: #{inspect(res)}")
    end

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_client_method(state, tun_name, "inventory", %{"data" => data}) do
    Logger.info("Get inventory data #{data}")
    set_inventory(tun_name, data)
    state
  end

  defp exec_client_method(state, _tun_name, method, _params) do
    Logger.error("Bad message method: #{method}")
    state
  end

  defp set_sslink_up(tun_name, sslink_name, link_state) do
    with tun_state = %TunState{} <- :ets.lookup_element(:tuns, tun_name, 4),
         sslinks <- tun_state.sslinks,
         sslink_state = %SSlinkState{} <- sslinks[sslink_name] || %SSlinkState{},
         new_tun_state <- %TunState{
           tun_state
           | sslinks: sslinks |> Map.put(sslink_name, %SSlinkState{sslink_state | up: link_state})
         } do
      :ets.update_element(
        :tuns,
        tun_name,
        {4, new_tun_state}
      )
    else
      res -> Logger.error("Can't set sslink state: #{inspect(res)}")
    end
  end

  defp set_inventory(tun_name, inventory) do
    with tun_state = %TunState{} <- :ets.lookup_element(:tuns, tun_name, 4),
         new_tun_state <- %TunState{
           tun_state
           | inventory: inventory
         } do
      :ets.update_element(
        :tuns,
        tun_name,
        {4, new_tun_state}
      )
    else
      res -> Logger.error("Can't set sslink state: #{inspect(res)}")
    end
  end

  defp exec_local_script(tun_name) do
    with {:ok, script} <- get_script(tun_name, :local) do
      Acari.exec_sh(script)
    else
      res -> Logger.error("Can't parse local script: #{inspect(res)}")
    end
  end

  defp exec_remote_script(tun_name) do
    with {:ok, script} <- get_script(tun_name, :remote),
         {:ok, json} <- Jason.encode(%{method: "exec_sh", params: %{script: script}}) do
      Acari.TunMan.send_tun_com(tun_name, Const.master_mes(), json)
    else
      res -> Logger.error("Can't parse remote script: #{inspect(res)}")
    end
  end

  defp get_script(tun_name, templ_id) do
    with [{_, params, peer_params, _}] <- :ets.lookup(:tuns, tun_name),
         %{params: config_params, script: %{} = script} <-
           AcariServer.NodeManager.get_node_with_script(tun_name),
         templ when is_binary(templ) <-
           AcariServer.Template.get_script_with_prefix(script, templ_id),
         assigns <- get_assigns(tun_name, params, peer_params, config_params),
         {script, nil} <- AcariServer.Template.eval(templ, assigns) do
      {:ok, script}
    else
      %AcariServer.NodeManager.Node{script: nil} -> {:error, "<NO_SCRIPT>"}
      res -> res
    end
  end

  defp get_assigns(tun_name, params, peer_params, config_params) do
    peer_params
    |> Enum.map(fn {k, v} -> {"peer_" <> k, v} end)
    |> Enum.concat(Map.to_list(Map.merge(config_params || %{}, params)))
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> List.insert_at(0, {:id, tun_name})
    |> Enum.into(%{})
  end

  # API
  #  def get_tuns_state() do
  #    :ets.match(:tuns, {:"$1", :_, :_, :_})
  #    |> Enum.map(fn [name] -> [name, Acari.get_all_links(name)] end)
  #  end

  def get_tuns_state() do
    :ets.tab2list(:tuns)
  end

  defp broadcast_link_event() do
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
end
