defmodule AcariServer.Mnesia.Attr do
  def server(), do: [:system_name, :name, :up, :opt]
  def tun(), do: [:name, :server_id, :state, :opt]

  # for link and event id = {dev, tun, node}
  def link(), do: [:id, :name, :server_id, :tun_id, :up, :state, :opt]
  def event(), do: [:id, :timestamp, :level, :header, :text]
  def stat(), do: [:key, :value]
  def zabbix(), do: [:id, :host, :key, :value, :timestamp]
  def session(), do: [:jti, :params, :activity]

  def table_list(), do: [:server, :tun, :link, :event, :stat, :zabbix, :session]

  def pattern(tab, field_pattern) do
    mk_record(tab, field_pattern, :_)
  end

  def mk_record(tab, fields_map, filler \\ nil) do
    [
      tab
      | apply(__MODULE__, tab, [])
        |> Enum.map(fn field ->
          case fields_map[field] do
            nil -> filler
            val -> val
          end
        end)
    ]
    |> List.to_tuple()
  end

  def record_to_map(rec) do
    [tab | fields] = Tuple.to_list(rec)

    Enum.zip(apply(__MODULE__, tab, []), fields)
    |> Enum.into(%{})
  end

  def merge_record([tab | _fields] = rec, fields_map) do
    new =
      rec
      |> record_to_map()
      |> Map.merge(fields_map)

    mk_record(tab, new)
  end
end

defmodule AcariServer.Mnesia.Rec do
  alias AcariServer.Mnesia.Attr
  require Record

  for i <- Attr.table_list() do
    Record.defrecord(i, apply(Attr, i, []))
  end
end

defmodule AcariServer.Mnesia do
  require Logger
  require AcariServer.Mnesia.Rec, as: Rec
  alias :mnesia, as: Mnesia
  alias AcariServer.Mnesia.Attr
  import AcariServer.Mnesia.Attr, only: [mk_record: 2]
  alias AcariServerWeb.Endpoint
  require Acari.Const

  def init() do
    Mnesia.start()

    servers_db = AcariServer.ServerManager.list_servers()

    servers_list_db =
      servers_db |> Enum.map(fn %{system_name: name} -> name |> String.to_atom() end)

    Mnesia.change_config(:extra_db_nodes, servers_list_db)
    table_list = Attr.table_list()
    Mnesia.wait_for_tables(table_list, 5000)

    existing_table_list = Mnesia.system_info(:tables)
    create_list = table_list -- existing_table_list

    Logger.info(
      "Start Mnesia: tables: #{inspect(existing_table_list)}, create: #{inspect(create_list)}"
    )

    for t <- create_list do
      Mnesia.create_table(t,
        attributes: apply(Attr, t, []),
        ram_copies: [node() | servers_list_db] |> Enum.uniq()
      )
    end

    update_servers_list(servers_db, true)
  end

  # server

  def update_servers_list() do
    servers_db = AcariServer.ServerManager.list_servers()
    update_servers_list(servers_db)
  end

  def update_servers_list(servers_db, first \\ nil) do
    node_list = [node() | Node.list()]

    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, _ ->
          Mnesia.delete_object(rec)
        end,
        nil,
        :server
      )

      servers_db
      |> Enum.each(fn %{system_name: system_name, name: name} ->
        system_name = system_name |> String.to_atom()

        Mnesia.write(
          Rec.server(
            system_name: system_name,
            name: name,
            up: Enum.member?(node_list, system_name)
          )
        )
      end)
    end)

    set_tun_distr()

    if is_master_server() do
      redistribute_tun()

      if first do
        Task.start(fn ->
          Process.sleep(1000)

          AcariServerWeb.Endpoint.broadcast!("room:lobby", "link_event", %{
            reload: true
          })
        end)
      end
    end
  end

  def get_down_servers() do
    match(:server, %{up: false}) |> Enum.map(fn %{name: name} -> name end)
  end

  def get_up_servers() do
    match(:server, %{up: true}) |> Enum.map(fn %{name: name} -> name end)
  end

  def is_master_server() do
    node() ==
      match(:server, %{up: true})
      |> Enum.min_by(fn %{name: name} -> name end, fn -> %{} end)
      |> Map.get(:system_name)
  end

  def get_unregistered_servers() do
    [node() | Node.list()] --
      (match(:server, %{})
       |> Enum.map(fn %{system_name: name} -> name end))
  end

  def get_node_to_name_map() do
    match(:server)
    |> Enum.map(fn %{name: name, system_name: system_name} ->
      {system_name, name}
    end)
    |> Enum.into(%{})
  end

  def get_server_name_by_system_name(system_name) do
    case Mnesia.transaction(fn ->
           Mnesia.read(:server, system_name)
         end) do
      {:atomic, [record]} -> record |> Rec.server(:name)
      _ -> system_name
    end
  end

  def delete_server(server) do
    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, acc ->
          case Rec.link(rec, :server_id) do
            ^server ->
              Mnesia.delete_object(rec)
              acc + 1

            _ ->
              acc
          end
        end,
        0,
        :link
      )

      Mnesia.foldl(
        fn rec, acc ->
          case Rec.event(rec, :id) do
            {_, _, ^server} ->
              Mnesia.delete_object(rec)
              acc + 1

            _ ->
              acc
          end
        end,
        0,
        :event
      )
    end)
  end

  # tun

  def add_tunnel(kl) do
    name = kl |> Keyword.get(:name)

    case Mnesia.transaction(fn ->
           case Mnesia.wread({:tun, name}) do
             [] ->
               serv = get_best_server()
               kl = kl |> Keyword.put(:server_id, serv)
               :ok = Mnesia.write(mk_record(:tun, kl))
               serv

             [record] ->
               record |> Rec.tun(:server_id)
           end
         end) do
      {:atomic, node} ->
        Phoenix.PubSub.broadcast(
          AcariServer.PubSub,
          "snd:#{name}",
          {:main_server, node}
        )

        set_tun_distr()
        node
    end
  end

  def del_tunnel(name) do
    Mnesia.transaction(fn ->
      Mnesia.delete({:tun, name})
    end)

    purge_stat()
  end

  def get_tunnels_num() do
    case Mnesia.table_info(:tun, :size) do
      n when is_number(n) -> n
      _ -> 0
    end
  end

  def update_tun_script(name, tag, data) do
    update_tun_state(name, tag, data)
  end

  def update_tun_state(name, tag, data) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:tun, name}) do
        [] ->
          Logger.error("#{name}: Can't set #{tag}, No such tunnel")

        [record] ->
          state =
            record
            |> Rec.tun(:state)
            |> Map.put(tag, data)

          Mnesia.write(Rec.tun(record, state: state))
          AcariServer.NodeMonitorAgent.event(name, tag |> to_string, data)
      end
    end)
  end

  def update_tun_server(name, server) do
    case Mnesia.transaction(fn ->
           case Mnesia.wread({:server, server}) do
             [] ->
               "No such server #{server}"

             [_] ->
               case Mnesia.wread({:tun, name}) do
                 [] ->
                   "No such tunnel #{name}"

                 [record] ->
                   Mnesia.write(Rec.tun(record, server_id: server))
               end
           end
         end) do
      {:atomic, :ok} ->
        Phoenix.PubSub.broadcast(
          AcariServer.PubSub,
          "snd:#{name}",
          {:main_server, server}
        )

        set_tun_distr()
        broadcast_link_event()

      {:atomic, err} ->
        Logger.error("update_tun_server: #{inspect(err)}")
    end
  end

  def get_tunnel_state(name) do
    node = AcariServer.NodeManager.get_node_by_name(name)

    case Mnesia.transaction(fn ->
           Mnesia.read({:tun, name})
         end) do
      {:atomic, [record]} ->
        record
        |> Rec.tun(:state)
        |> Map.merge(%{
          name: name,
          description: node.description,
          server:
            record
            |> Rec.tun(:server_id)
            |> get_server_name_by_system_name()
        })

      _ ->
        nil
    end
  end

  def set_tun_distr() do
    case Mnesia.transaction(fn ->
           Mnesia.foldl(
             fn rec, acc ->
               serv = Rec.tun(rec, :server_id)

               case acc do
                 %{^serv => n} -> Map.put(acc, serv, n + 1)
                 _ -> Map.put(acc, serv, 1)
               end
             end,
             match(:server)
             |> Enum.map(fn %{system_name: name} -> {name, 0} end)
             |> Enum.into(%{}),
             :tun
           )
         end) do
      {:atomic, distr} ->
        node_to_name = get_node_to_name_map()

        {list, sum} =
          distr
          |> Enum.map_reduce(0, fn {node, num}, acc ->
            {{node, node_to_name[node], num}, acc + num}
          end)

        list =
          list
          |> Enum.map(fn {node, name, q} ->
            {node, name, q, if(sum == 0, do: 0, else: 100 * q / sum)}
          end)

        set_stat(:tun_distr, {list, sum})

      _ ->
        nil
    end
  end

  def get_main_server(tun_name) do
    case Mnesia.transaction(fn ->
           Mnesia.read({:tun, tun_name})
         end) do
      {:atomic, [record]} ->
        record
        |> Rec.tun(:server_id)

      _ ->
        nil
    end
  end

  def get_best_server() do
    with {[{node, _, _, _} | _] = server_list, _} when not is_nil(node) <- get_tun_distr() do
      down_server_list = get_down_servers()

      server_list
      |> Enum.reject(fn {_, name, _, _} -> Enum.member?(down_server_list, name) end)
      |> Enum.min_by(fn {_, _, num, _} -> num end)
      |> elem(0)
    else
      _ -> node()
    end
  end

  def redistribute_tun() do
    with {server_list, tun_num} when is_integer(tun_num) and tun_num > 0 <-
           get_tun_distr(),
         up_server_list <- get_up_servers(),
         up_server_num when up_server_num > 0 <-
           length(up_server_list) do
      avg_tun_num = tun_num / up_server_num

      {decr, incr} =
        server_list
        |> Enum.map(fn {node, name, num, _} ->
          {node,
           case Enum.member?(up_server_list, name) do
             true -> round(avg_tun_num - num)
             _ -> -tun_num
           end}
        end)
        |> Enum.split_with(fn {_, inc} -> inc < 0 end)

      decr = decr |> Enum.into(%{})
      incr = incr |> Enum.into(%{})

      Mnesia.transaction(fn ->
        Mnesia.foldl(
          fn rec, {decr, incr} = acc ->
            server = Rec.tun(rec, :server_id)

            case decr[server] do
              num when is_integer(num) and num < 0 ->
                {new_server, new_num} = incr |> Enum.max_by(fn {_, n} -> n end)
                Mnesia.write(Rec.tun(rec, server_id: new_server))

                Phoenix.PubSub.broadcast(
                  AcariServer.PubSub,
                  "snd:#{Rec.tun(rec, :name)}",
                  {:main_server, new_server}
                )

                {decr |> Map.put(server, num + 1), incr |> Map.put(new_server, new_num - 1)}

              _ ->
                acc
            end
          end,
          {decr, incr},
          :tun
        )
      end)

      set_tun_distr()
      broadcast_link_event()
    end
  end

  # link

  def update_link(name, tun, up) do
    node = node()
    id = {name, tun, node}
    tm = :erlang.system_time(:second)

    Mnesia.transaction(fn ->
      state =
        case Mnesia.wread({:link, id}) do
          [] -> %{down_count: 0, tm_start: tm, tm_down: 0, tm_down_start: tm}
          [record] -> record |> Rec.link(:state)
        end

      state =
        case up do
          true -> %{state | tm_down: state.tm_down + tm - state.tm_down_start}
          _ -> %{state | down_count: state.down_count + 1, tm_down_start: tm}
        end

      Mnesia.write(
        Rec.link(id: id, name: name, tun_id: tun, server_id: node, up: up, state: state)
      )
    end)

    node_to_name = get_node_to_name_map()

    {level, port_list, mes} =
      get_link_list_for_tunnel(tun)
      |> reduce_link_list(node_to_name)
      |> alert_mes()

    case up do
      true ->
        delete_event(id)

        Mnesia.transaction(fn ->
          match_clean(:event, %{header: tun})
          |> Enum.each(fn %{id: {name, _tun, node}, level: prev_level} = event ->
            if level > prev_level or (level == 2 and prev_level == 2) do
              Mnesia.write(
                mk_record(
                  :event,
                  event
                  |> Map.merge(%{
                    level: level,
                    text: "Соединение #{name}@#{node_to_name[node]} упало. #{mes}"
                  })
                )
              )
            end
          end)
        end)

        update_stat(:down_port, fn
          {_, list} ->
            list = list |> Enum.reject(fn x -> x == {tun, name} end)
            {length(list), list}

          _ ->
            nil
        end)

        AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive[#{name}]", 1)

        {num, _} =
          update_stat(:down_tun, fn
            {_, list} ->
              list = list |> Enum.reject(fn x -> x == tun end)
              {length(list), list}

            _ ->
              {0, []}
          end)

        AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive", 1)
        update_active_tun_chart(num)

        if get_main_server(tun) == node() do
          Acari.TunMan.send_all_link_com(tun, Acari.Const.prio(), <<1>>)
        else
          Acari.TunMan.send_all_link_com(tun, Acari.Const.prio(), <<0>>)
        end

      # down
      _ ->
        update_event(%{
          id: id,
          level: level,
          header: tun,
          text: "Соединение #{name}@#{node_to_name[node]} упало. #{mes}"
        })

        if level == 1 do
          {num, _} =
            update_stat(:down_tun, fn
              {_, list} ->
                list = [tun | list] |> Enum.uniq()
                {length(list), list}

              _ ->
                {1, [tun]}
            end)

          AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive", 0)
          update_active_tun_chart(num)
        end

        if level == 1 or Enum.member?(port_list, name) do
          update_stat(:down_port, fn
            {_, list} ->
              list = [{tun, name} | list] |> Enum.uniq()
              {length(list), list}

            _ ->
              {1, [{tun, name}]}
          end)

          AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive[#{name}]", 0)
        end
    end

    broadcast_link_event()
  end

  @max_items 25
  def update_active_tun_chart(bad) do
    tun_num = get_tunnels_num()
    num = tun_num - bad

    tran =
      Mnesia.transaction(fn ->
        old =
          case Mnesia.wread({:stat, :active_tun}) do
            [{:stat, :active_tun, value}] -> value
            _ -> nil
          end

        new =
          case old do
            [ts_list, [prev | _] = num_list] ->
              case prev == num do
                true ->
                  nil

                _ ->
                  [
                    [:os.system_time(:second) | ts_list] |> Enum.take(@max_items),
                    [num | num_list] |> Enum.take(@max_items)
                  ]
              end

            _ ->
              [[:os.system_time(:second)], [num]]
          end

        case new do
          nil -> nil
          new -> Mnesia.write({:stat, :active_tun, new})
        end
      end)

    case tran do
      {:atomic, :ok} ->
        Endpoint.broadcast!("room:lobby", "link_event", %{
          redraw_chart: true
        })

        AcariServer.Zabbix.ZbxApi.zbx_send_master(
          "acari.clients.number",
          to_string(tun_num)
        )

        AcariServer.Zabbix.ZbxApi.zbx_send_master("acari.clients.active", to_string(num))

      _ ->
        nil
    end
  end

  def broadcast_link_event() do
    mes_list = AcariServerWeb.LayoutView.get_mes()

    mes_html =
      Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "messages.html", mes_list: mes_list)

    statistics_html =
      Phoenix.View.render_to_string(AcariServerWeb.PageView, "statistics.html", [])

    progress_html = Phoenix.View.render_to_string(AcariServerWeb.PageView, "progress.html", [])

    Endpoint.broadcast!("room:lobby", "link_event", %{
      num_of_mes: mes_list |> length(),
      messages: mes_html,
      statistics: statistics_html,
      progress: progress_html
    })
  end

  def broadcast_sessions() do
    sessions_html = Phoenix.View.render_to_string(AcariServerWeb.PageView, "session.html", [])

    Endpoint.broadcast!("room:lobby", "link_event", %{
      sessions: sessions_html
    })
  end

  # event

  def update_event(ev) do
    ev = ev |> Map.put(:timestamp, :os.system_time(:microsecond))

    Mnesia.transaction(fn ->
      Mnesia.write(mk_record(:event, ev))
    end)
  end

  def delete_event(id) do
    Mnesia.transaction(fn ->
      Mnesia.delete({:event, id})
    end)
  end

  def get_event_list() do
    match(:event)
  end

  defp purge_link_table(tab) do
    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, acc ->
          case Rec.event(rec, :id) do
            {_dev, tun, node} ->
              if Mnesia.wread({:tun, tun}) == [] or
                   Mnesia.wread({:server, node}) == [] do
                Mnesia.delete_object(rec)
                acc + 1
              else
                acc
              end

            _ ->
              acc
          end
        end,
        0,
        tab
      )
    end)
  end

  def purge_stat() do
    # clean link and event lists
    purge_link_table(:link)
    purge_link_table(:event)

    # Clean down_tun
    {num, _} =
      update_stat(:down_tun, fn
        {_, list} ->
          all_tun = Mnesia.dirty_all_keys(:tun)
          list = MapSet.intersection(MapSet.new(list), MapSet.new(all_tun)) |> MapSet.to_list()
          {length(list), list}

        _ ->
          {0, []}
      end)

    update_active_tun_chart(num)

    # Clean down_port
    update_stat(:down_port, fn
      {_, list} ->
        all_ports =
          Mnesia.dirty_all_keys(:link)
          |> Enum.map(fn {dev, tun, _} -> {tun, dev} end)
          |> Enum.uniq()

        list = MapSet.intersection(MapSet.new(list), MapSet.new(all_ports)) |> MapSet.to_list()
        {length(list), list}

      _ ->
        nil
    end)

    broadcast_link_event()
  end

  # state

  def set_stat(key, value) do
    Mnesia.transaction(fn ->
      Mnesia.write({:stat, key, value})
    end)
  end

  def update_stat(key, func) do
    Mnesia.transaction(fn ->
      value =
        case Mnesia.wread({:stat, key}) do
          [{:stat, ^key, value}] -> value
          _ -> nil
        end
        |> func.()

      :ok = Mnesia.write({:stat, key, value})
      value
    end)
    |> elem(1)
  end

  # zabbix

  def update_zabbix(host, key, value) do
    id = {host, key}
    ts = :os.system_time(:second)

    Mnesia.transaction(fn ->
      Mnesia.write(Rec.zabbix(id: id, host: host, key: key, value: value, timestamp: ts))
    end)
  end

  def get_zabbix(host) do
    match(:zabbix, %{host: host})
  end

  # session

  def add_session(jti, params) do
    Mnesia.transaction(fn ->
      Mnesia.write({:session, jti, params, :os.system_time(:second)})
    end)

    broadcast_sessions()
  end

  def delete_session(jti) do
    Mnesia.transaction(fn ->
      Mnesia.delete({:session, jti})
    end)

    broadcast_sessions()
  end

  def update_session_activity(jti) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:session, jti}) do
        [] ->
          Logger.error("No session with jti = #{jti}")

        [record] ->
          Mnesia.write(Rec.session(record, activity: :os.system_time(:second)))
          broadcast_sessions()
      end
    end)
  end

  def get_sessions() do
    node_to_name = get_node_to_name_map()
    tm = :os.system_time(:second)

    match(:session)
    |> Enum.reject(fn %{params: params, activity: act} ->
      if params["exp"] < tm, do: delete_session(params["jti"])
      act + 15 * 60 < tm
    end)
    |> Enum.map(fn %{params: params} = item ->
      item |> put_in([:params, :server], node_to_name[params.server])
    end)
    |> Enum.sort_by(fn %{params: params} -> params["iat"] end, &>=/2)
  end

  # API

  def get_active_tun_chart() do
    case Mnesia.transaction(fn -> Mnesia.read({:stat, :active_tun}) end) do
      {:atomic, [{:stat, :active_tun, chart}]} when is_list(chart) -> chart
      _ -> [[], []]
    end
  end

  def get_down_tun_num() do
    case Mnesia.transaction(fn -> Mnesia.read({:stat, :down_tun}) end) do
      {:atomic, [{:stat, :down_tun, {num, _}}]} -> num
      _ -> 0
    end
  end

  def get_down_port_num() do
    case Mnesia.transaction(fn -> Mnesia.dirty_read({:stat, :down_port}) end) do
      {:atomic, [{:stat, :down_port, {num, _}}]} -> num
      _ -> 0
    end
  end

  def get_tun_distr() do
    case Mnesia.transaction(fn -> Mnesia.dirty_read({:stat, :tun_distr}) end) do
      {:atomic, [{:stat, :tun_distr, distr}]} -> distr
      _ -> {[{nil, "нет данных", 0, 100}], 0}
    end
  end

  def get_tunnel_list(nodes) do
    node_to_name = get_node_to_name_map()

    name_to_server =
      match(:tun)
      |> Enum.map(fn %{name: name, server_id: server} -> {name, server} end)
      |> Enum.into(%{})

    status =
      match(:link)
      |> link_list_to_map()

    nodes
    |> Enum.map(fn %{name: name, description: descr, latitude: lat, longitude: lng} ->
      %{
        name: name,
        description: descr,
        latitude: lat,
        longitude: lng,
        server: node_to_name[name_to_server[name]]
      }
      |> Map.merge(
        case status[name] do
          nil -> %{}
          link_list -> link_list |> reduce_link_list(node_to_name) |> alert()
        end
      )
    end)
  end

  def get_link_list_for_tunnel(tun_name) do
    match(:link, %{tun_id: tun_name})
  end

  def match(tab, field_pattern \\ %{}) do
    case Mnesia.transaction(fn ->
           Mnesia.match_object(Attr.pattern(tab, field_pattern))
         end) do
      {:atomic, rec_list} ->
        rec_list |> Enum.map(fn r -> r |> Attr.record_to_map() end)

      _ ->
        []
    end
  end

  def match_clean(tab, field_pattern \\ %{}) do
    case Mnesia.match_object(Attr.pattern(tab, field_pattern)) do
      rec_list when is_list(rec_list) ->
        rec_list |> Enum.map(fn r -> r |> Attr.record_to_map() end)

      _ ->
        []
    end
  end

  def link_list_to_map(link_list) do
    link_list
    |> Enum.reduce(%{}, fn %{tun_id: tun_name} = link, acc ->
      new_link_list =
        case acc[tun_name] do
          list when is_list(list) -> [link | list]
          nil -> [link]
        end

      acc |> Map.put(tun_name, new_link_list)
    end)
    |> Enum.into(%{})
  end

  def reduce_link_list(link_list, node_to_name) do
    link_list
    |> Enum.reduce(
      %{links_up: [], links_down: []},
      fn %{name: name, server_id: server_id, up: up}, %{links_up: lu, links_down: ld} ->
        server = node_to_name[server_id] || server_id

        case up do
          true -> %{links_up: [{name, server} | lu], links_down: ld}
          _ -> %{links_up: lu, links_down: [{name, server} | ld]}
        end
      end
    )
  end

  defp alert(%{links_up: [], links_down: ld}), do: %{alert: 1, links_down: ld |> get_links_str()}
  defp alert(%{links_up: lu, links_down: []}), do: %{alert: 4, links_up: lu |> get_links_str()}

  defp alert(%{links_up: lu, links_down: ld}) do
    alert =
      if get_serv(ld) -- get_serv(lu) == [] and get_link(ld) -- get_link(lu) == [] do
        3
      else
        2
      end

    %{alert: alert, links_up: lu |> get_links_str(), links_down: ld |> get_links_str()}
  end

  defp alert_mes(%{links_up: [], links_down: ld}), do: {1, ld, "Устройство недоступно"}
  defp alert_mes(%{links_up: _lu, links_down: []}), do: {4, [], ""}

  defp alert_mes(%{links_up: lu, links_down: ld}) do
    port_list = get_link(ld) -- get_link(lu)

    case [
           case get_serv(ld) -- get_serv(lu) do
             [] -> nil
             serv_list -> "Нет связи с сервером #{serv_list |> Enum.join(", ")}"
           end,
           case port_list do
             [] -> nil
             port_list -> "Порт #{port_list |> Enum.join(", ")} не работает"
           end
         ]
         |> Enum.reject(&is_nil/1)
         |> Enum.join(", ") do
      "" -> {3, [], ""}
      mes -> {2, port_list, mes}
    end
  end

  defp get_link(l), do: l |> Enum.map(fn {l, _} -> l end) |> Enum.uniq()
  defp get_serv(l), do: l |> Enum.map(fn {_, s} -> s end) |> Enum.uniq()

  defp get_links_str(l) do
    l |> Enum.map(fn {l, s} -> "#{l}@#{s}" end) |> Enum.join(", ")
  end
end
