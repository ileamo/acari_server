defmodule AcariServer.Master do
  use GenServer
  require Logger
  alias AcariServer.Mnesia

  defmodule State do
    defstruct [
      :tuns
    ]
  end

  defmodule TunState do
    defstruct [
      :node,
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
  def handle_call(:sslinks_state, _from, state) do
    {:reply, get_sslinks_state(), state}
  end

  def handle_call(msg, _from, state) do
    Logger.error("Master: Bad call #{inspect(msg)}")
    {:reply, nil, state}
  end

  defp get_sslinks_state() do
    :ets.tab2list(:tuns)
    |> Enum.map(fn {name, _, _, state} -> {name, state} end)
    |> Enum.into(%{})
    |> Enum.map(fn {tun_name, tun_state} ->
      {tun_name, AcariServer.Master.get_sslinks(tun_state)}
    end)
    |> Enum.into(%{})
  end

  @impl true
  def handle_cast({:tun_started, %{tun_name: tun_name} = tun_state}, state) do
    Logger.info("Master get :tun_started from #{tun_name}, tun_state = #{inspect(tun_state)}")
    params = %{"ifname" => tun_state.ifname}
    peer_params = tun_state.peer_params
    :ets.insert(:tuns, {tun_name, params, peer_params, %TunState{}})

    # server =
    Mnesia.add_tunnel(
      name: tun_name,
      server_id: node(),
      state: %{},
      srv_state: %{}
    )

    # if server == node() do
    exec_local_script(tun_name)
    # end

    {:noreply, state}
  end

  def handle_cast({:peer_started, tun_name}, state) do
    Logger.debug("Master get :peer_started from #{tun_name}")

    {:noreply, state}
  end

  def handle_cast({:sslink_opened, tun_name, sslink_name, opts}, state) do
    set_sslink_up(tun_name, sslink_name, true, opts)
    {:noreply, state}
  end

  def handle_cast({:sslink_closed, tun_name, sslink_name, opts}, state) do
    set_sslink_up(tun_name, sslink_name, false, opts)
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

  def handle_cast({:del_tun, tun_name}, state) do
    Acari.TunsSup.stop_tun(tun_name)

    Logger.info("Tunnel #{tun_name} deleted")
    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_server_method(state, tun_name, "put.data", %{"id" => script_id, "data" => data}) do
    # Logger.info("Get script data #{data}")
    set_script(tun_name, script_id, to_string(data))
    state
  end

  defp exec_server_method(state, tun_name, "get.conf", %{"id" => tun_name} = params) do
    Logger.info("#{tun_name}: Get config request #{inspect(params)}")
    send_config(params)
    state
  end

  defp exec_server_method(state, tun_name, "get.conf", params) do
    Logger.error("#{tun_name}: Bad config request #{inspect(params)}")
    state
  end

  defp exec_server_method(state, _tun_name, method, _params) do
    Logger.error("Bad message method: #{method}")
    state
  end

  defp set_sslink_up(tun_name, sslink_name, link_state, opts) do
    with [{_, _, _, tun_state = %TunState{}}] <- :ets.lookup(:tuns, tun_name),
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
      :ets.update_element(
        :tuns,
        tun_name,
        {4, tun_state}
      )

      Mnesia.update_link(sslink_name, tun_name, link_state, opts)
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

  def set_script(tun_name, script_id, data) do
    data = %{timestamp: :os.system_time(:second), data: data}
    AcariServer.Mnesia.update_tun_script(tun_name, script_id, data)
  end

  def exec_local_script(tun_name, template \\ :local) do
    run_script_on_server(tun_name, template)
  end

  def send_config(%{"id" => tun_name} = params) do
    request = %{
      method: "put.conf",
      params: %{
        script: 0
      }
    }

    {script, _} = AcariServer.SFX.create_script_from_template(tun_name, :remote, params)

    Acari.TunMan.send_master_mes_plus(tun_name, request, [script])
  end

  def exec_script_on_peer(tun_name, templ, params \\ %{}) do
    request = %{
      method: "get_exec_sh",
      params: %{
        id: templ,
        script: 0
      }
    }

    {script, _} = AcariServer.SFX.create_script_from_template(tun_name, templ, params)
    Acari.TunMan.send_master_mes_plus(tun_name, request, [script])
  end

  def get_tun_params(tun_name) do
    with [{_, params, peer_params, _}] <- :ets.lookup(:tuns, tun_name) do
      peer_params
      |> Enum.map(fn {k, v} -> {"peer_" <> k, v} end)
      |> Enum.concat(Map.to_list(params))
      |> List.insert_at(0, {"id", tun_name})
      |> Enum.into(%{})
    else
      _ -> %{}
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
         # TODO find more common algorithm
         {_, _, _, _} = dstaddr <- addr_list[:dstaddr] || addr_list[:broadaddr],
         dstaddr when is_list(dstaddr) <- :inet.ntoa(dstaddr) do
      to_string(dstaddr)
    else
      _ -> nil
    end
  end

  def get_tuns_state() do
    :ets.tab2list(:tuns)
  end

  def get_nodes_num() do
    case :ets.info(:tuns, :size) do
      n when is_number(n) -> n
      _ -> 0
    end
  end

  def get_sslinks(nil), do: %{links_up: nil, links_down: nil}

  def get_sslinks(tun_state) do
    tun_state.sslinks
    |> Enum.reduce(
      %{links_up: [], links_down: []},
      fn
        {name, %{up: true}}, %{links_up: links_up} = acc ->
          %{acc | links_up: [name | links_up]}

        {name, %{up: _}}, %{links_down: links_down} = acc ->
          %{acc | links_down: [name | links_down]}
      end
    )
    |> Enum.map(fn
      {k, []} -> {k, nil}
      {k, list} -> {k, Enum.join(list, ", ")}
    end)
    |> Enum.into(%{})
  end

  def delete_tunnel(tun_name) do
    AcariServer.Mnesia.del_tunnel(tun_name)

    [node() | Node.list()]
    |> Enum.each(fn node ->
      GenServer.cast({__MODULE__, node}, {:del_tun, tun_name})
    end)

    # Task.start(fn ->
    #   Process.sleep(5_000)
    #   AcariServer.Mnesia.del_tunnel(tun_name)
    # end)
  end

  def run_script_on_server(tun_name, template, node \\ Node.self()) do
    try do
      Task.Supervisor.start_child(
        {AcariServer.TaskSup, node},
        AcariServer.Master,
        :exec_sh,
        [tun_name, template, []]
      )
    catch
      _, _ -> nil
    end
  end

  def run_script_on_all_servers(tun_name, tag) do
    AcariServer.Mnesia.get_up_servers(:system_name)
    |> Enum.each(fn node -> AcariServer.Master.run_script_on_server(tun_name, tag, node) end)
  end

  def exec_sh(tun_name, template, env \\ []) do
    {script, templ_name} = AcariServer.SFX.create_script_from_template(tun_name, template, %{})

    case System.cmd("sh", ["-c", script |> String.replace("\r\n", "\n")],
           stderr_to_stdout: true,
           env: env
         ) do
      {data, _code} ->
        AcariServer.Mnesia.update_tun_srv_state(tun_name, templ_name, Node.self(), %{
          timestamp: :os.system_time(:second),
          data: data
        })

      _ ->
        nil
    end
  end
end
