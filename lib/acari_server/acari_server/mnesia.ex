defmodule AcariServer.Mnesia.Attr do
  def counter(), do: [:key, :count]
  def server(), do: [:system_name, :name, :up, :opt]
  def db(), do: [:id, :up, :opt]
  def tun(), do: [:name, :server_id, :state, :srv_state, :opt]

  # for link and event id = {dev, tun, node}
  def link(), do: [:id, :name, :server_id, :tun_id, :up, :state, :opt]
  # TODO delete :event after db migration
  def event(), do: [:id, :count, :timestamp, :level, :header, :text]
  def client_status(), do: [:name, :timestamp, :opts]
  def stat(), do: [:key, :value]
  def zabbix(), do: [:id, :host, :key, :value, :timestamp]
  def zbx_hostgroup(), do: [:name, :hostgroupid]
  def zbx_host(), do: [:name, :hostid, :items]
  def session(), do: [:jti, :params, :activity]

  def table_list(),
    do: [
      :counter,
      :server,
      :db,
      :tun,
      :link,
      :event,
      :client_status,
      :stat,
      :zabbix,
      :zbx_hostgroup,
      :zbx_host,
      :session
    ]

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
  require AcariServer.Zabbix.ZbxConst, as: ZbxConst

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
    purge_zabbix()
  end

  # server

  def update_servers_list() do
    servers_db =
      try do
        AcariServer.ServerManager.list_servers()
      rescue
        _ -> nil
      end

    update_servers_list(servers_db)
  end

  def update_servers_list(servers_db, first \\ nil) do
    node_list = [node() | Node.list()]

    # add ram copies
    if servers_db do
      server_list =
        servers_db
        |> Enum.map(fn %{system_name: system_name} -> String.to_atom(system_name) end)
        # TODO Надо копировать данные в неизвестный сервер?
        |> Enum.concat([Node.self() | Node.list()])
        |> Enum.uniq()

      Attr.table_list()
      |> Enum.each(fn tab ->
        ram_copies = Mnesia.table_info(tab, :ram_copies)

        new = server_list -- ram_copies

        old = ram_copies -- server_list

        new
        |> Enum.each(fn node ->
          Mnesia.add_table_copy(tab, node, :ram_copies)
        end)

        old
        |> Enum.each(fn node ->
          Mnesia.del_table_copy(tab, node)
        end)
      end)
    end

    Mnesia.transaction(fn ->
      servers_db = servers_db || match_clean(:server)

      Mnesia.foldl(
        fn rec, _ ->
          Mnesia.delete_object(rec)
        end,
        nil,
        :server
      )

      servers_db
      |> Enum.each(fn %{system_name: system_name, name: name} ->
        system_name =
          if is_binary(system_name), do: String.to_atom(system_name), else: system_name

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
    server_and_db_alert()

    if is_master_server() do
      redistribute_tun()

      if first do
        Task.start(fn ->
          Process.sleep(1000)

          server_and_db_alert()
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

  def get_up_servers(:system_name) do
    match(:server, %{up: true}) |> Enum.map(fn %{system_name: name} -> name end)
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

      purge_client_status_table()
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

    delete_zabbix(name)
    purge_stat()
  end

  def is_tunnel(name) do
    case Mnesia.dirty_read(:tun, name) do
      [] -> false
      _ -> true
    end
  end

  def get_tunnels_num() do
    case Mnesia.table_info(:tun, :size) do
      n when is_number(n) -> n
      _ -> 0
    end
  end

  def update_tun_script(name, tag, data) do
    update_tun_state(name, tag, data, rcv_event: true)
    send_to_zabbix(name, tag, data)
  end

  defp send_to_zabbix(host, templ_name, data) do
    with %{data: data} <- data,
         %AcariServer.TemplateManager.Template{zabbix_key: key}
         when is_binary(key) <-
           AcariServer.TemplateManager.get_template_by_name(templ_name),
         true <- String.trim(key) != "" do
      update_zabbix(host, key, to_string(data))
      AcariServer.Zabbix.ZbxApi.zbx_send(host, key, data)
    end
  end

  def update_tun_opt(name, path, update_fn) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:tun, name}) do
        [] ->
          Logger.error("#{name}: Can't update tun opt, No such tunnel")

        [record] ->
          opt = Rec.tun(record, :opt) || %{}
          path = Enum.map(path, &Access.key(&1, %{}))
          {_, opt} = get_and_update_in(opt, path, &{&1, update_fn.(&1)})
          Mnesia.write(Rec.tun(record, opt: opt))
      end
    end)
  end

  def get_tun_opt(name) do
    case Mnesia.dirty_read(:tun, name) do
      [] -> nil
      [record] -> Rec.tun(record, :opt) || %{}
    end
  end

  defp update_tun_opt_alive(name, status) do
    ct = fn _ -> :erlang.system_time(:second) end

    case status do
      true -> update_tun_opt(name, [:last_up], ct)
      false -> update_tun_opt(name, [:last_down], ct)
    end
  end

  def update_tun_state(name, tag, data, opts \\ []) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:tun, name}) do
        [] ->
          Logger.error("#{name}: Can't set #{tag}, No such tunnel")

        [record] ->
          state =
            record
            |> Rec.tun(:state)
            |> Map.update(tag, data, fn old_data ->
              merge =
                case opts[:merge] do
                  func when is_function(func) -> func
                  _ -> &Map.merge/2
                end

              merge.(old_data, data)
              |> Enum.reject(fn
                {_, nil} -> true
                _ -> false
              end)
              |> Enum.into(%{})
            end)

          Mnesia.write(Rec.tun(record, state: state))

          if opts[:rcv_event] do
            AcariServer.NodeMonitorAgent.event(name, tag |> to_string, data)
          end
      end
    end)
  end

  def update_tun_srv_state(name, tag, node, data) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:tun, name}) do
        [] ->
          Logger.error("#{name}: Can't set #{tag}, No such tunnel")

        [record] ->
          srv_state =
            record
            |> Rec.tun(:srv_state)
            |> Map.put_new(tag, %{})
            |> update_in([tag, node], fn
              old_data when is_map(old_data) -> old_data |> Map.merge(data)
              _ -> data
            end)

          Mnesia.write(Rec.tun(record, srv_state: srv_state))
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

    if node do
      case Mnesia.transaction(fn ->
             Mnesia.read({:tun, name})
           end) do
        {:atomic, [record]} ->
          record
          |> Rec.tun(:state)
          |> Map.merge(%{
            id: node.id,
            name: name,
            description: node.description,
            address: node.address,
            server:
              record
              |> Rec.tun(:server_id)
              |> get_server_name_by_system_name(),
            in_work: true
          })

        _ ->
          %{
            id: node.id,
            name: name,
            description: node.description,
            address: node.address,
            server: nil,
            in_work: false
          }
      end
    else
      nil
    end
  end

  def get_tunnel_srv_state(name) do
    case Mnesia.transaction(fn ->
           Mnesia.read({:tun, name})
         end) do
      {:atomic, [record]} ->
        record
        |> Rec.tun(:srv_state)

      _ ->
        %{}
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
             match_clean(:server)
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
      |> Enum.min_by(fn {_, _, num, _} -> num end, fn -> {node()} end)
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

  def update_link(name, tun, up, opts \\ []) do
    node = node()
    id = {name, tun, node}
    tm = :erlang.system_time(:second)
    node_to_name = get_node_to_name_map()

    Mnesia.transaction(fn ->
      state =
        case Mnesia.wread({:link, id}) do
          [] ->
            %{
              down_count: 0,
              tm_start: tm,
              tm_down: 0,
              tm_down_start: tm,
              tm_up_start: tm,
              opts: %{}
            }

          [record] ->
            record |> Rec.link(:state)
        end

      state =
        case up do
          true ->
            %{
              state
              | tm_down: state.tm_down + tm - state.tm_down_start,
                tm_up_start: tm,
                opts: opts |> Enum.into(state.opts || %{})
            }

          _ ->
            %{state | down_count: state.down_count + 1, tm_down_start: tm}
        end

      Mnesia.write(
        Rec.link(id: id, name: name, tun_id: tun, server_id: node, up: up, state: state)
      )

      {level, port_list, mes} = create_tun_status_mes(tun, node_to_name)

      empty = [] == (rec_list = Mnesia.read(:client_status, tun))

      if not empty or level != 4 do
        Mnesia.write(
          Rec.client_status(
            name: tun,
            timestamp: :os.system_time(:microsecond),
            opts: %{
              level: level,
              text: mes,
              description:
                (rec_list != [] && Rec.client_status(hd(rec_list), :opts)[:description]) ||
                  AcariServer.NodeManager.get_client_description_by_name(tun)
            }
          )
        )

        if level == 4 do
          purge_client_status_table()
        end
      end

      case up do
        true ->
          update_stat(:down_port, fn
            {_, list} ->
              list = list |> Enum.reject(fn x -> x == {tun, name} end)
              {length(list), list}

            _ ->
              nil
          end)

          AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive[#{name}]", 1)
          AcariServer.Zabbix.Handler.wizard_clear_port(tun, name)

          {num, _} =
            update_stat(:down_tun, fn
              {_, list} ->
                list = list |> Enum.reject(fn x -> x == tun end)
                {length(list), list}

              _ ->
                {0, []}
            end)

          AcariServer.Zabbix.ZbxApi.zbx_send(tun, "alive", 1)
          update_tun_opt_alive(tun, true)
          update_active_tun_chart(num)

          if get_main_server(tun) == node() do
            Acari.TunMan.send_all_link_com(tun, Acari.Const.prio(), <<1>>)
          else
            Acari.TunMan.send_all_link_com(tun, Acari.Const.prio(), <<0>>)
          end

        # down
        _ ->
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
            update_tun_opt_alive(tun, false)
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
    end)

    broadcast_link_event()

    Phoenix.PubSub.broadcast(
      AcariServer.PubSub,
      "link_state:#{tun}",
      {:update_link, name, node, up}
    )
  end

  defp create_tun_status_mes(tun, node_to_name) do
    get_link_list_for_tunnel(tun, :clean)
    |> reduce_link_list(node_to_name)
    |> alert_mes()
  end

  @max_items 32
  defp update_active_tun_chart(bad) when is_integer(bad) do
    tun_num = get_tunnels_num()
    num = tun_num - bad

    :telemetry.execute([:bogatka, :clients], %{active: num})

    set_stat(:clients_number, {tun_num, num})

    AcariServer.Zabbix.ZbxApi.zbx_send_master(
      ZbxConst.client_number_key(),
      to_string(tun_num)
    )

    AcariServer.Zabbix.ZbxApi.zbx_send_master(ZbxConst.client_active_key(), to_string(num))

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

      _ ->
        nil
    end
  end

  defp update_active_tun_chart(_bad), do: nil

  defp broadcast_link_event() do
    mes_list = get_client_status()

    statistics_html =
      Phoenix.View.render_to_string(AcariServerWeb.PageView, "statistics.html", [])

    progress_html = Phoenix.View.render_to_string(AcariServerWeb.PageView, "progress.html", [])

    Endpoint.broadcast!("room:lobby", "link_event", %{
      statistics: statistics_html,
      progress: progress_html
    })

    Endpoint.broadcast!("room:lobby", "link_event_mes", %{
      mes_list: mes_list
    })
  end

  def server_and_db_alert() do
    Task.start(fn ->
      alert_html =
        Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "alert_server_db.html", [])

      AcariServerWeb.Endpoint.broadcast!("room:lobby", "link_event", %{
        alert: alert_html
      })
    end)
  end

  # client_status
  def get_client_status() do
    match(:client_status)
  end

  def get_client_status(user) do
    match(:client_status)
    |> get_client_status(user)
  end

  def get_client_status(list, user) do
    node_id_list = AcariServer.UserManager.get_node_id_list_for_user(user)

    case node_id_list do
      l when is_list(l) ->
        list
        |> Enum.filter(fn %{name: client_name} ->
          Enum.member?(node_id_list, AcariServer.NodeManager.get_node_by_name(client_name).id)
        end)

      _ ->
        list
    end
    |> Enum.sort_by(fn %{timestamp: ts} -> ts end, &>/2)
  end

  defp purge_link_table() do
    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, acc ->
          case Rec.link(rec, :id) do
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
        :link
      )
    end)
  end

  defp purge_client_status_table() do
    node_to_name = get_node_to_name_map()

    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, acc ->
          tun = Rec.client_status(rec, :name)

          if Mnesia.wread({:tun, tun}) == [] do
            Mnesia.delete_object(rec)
            acc + 1
          else
            {level, port_list, mes} = create_tun_status_mes(tun, node_to_name)

            cond do
              (level == 4 and
                 :os.system_time(:microsecond) - (rec |> Rec.client_status(:timestamp)) >
                   60_000_000) or (level == 1 and port_list == []) ->
                Mnesia.delete_object(rec)

              true ->
                Mnesia.write(
                  Rec.client_status(
                    name: tun,
                    timestamp: Rec.client_status(rec, :timestamp),
                    opts: %{
                      level: level,
                      text: mes,
                      description: Rec.client_status(rec, :opts)[:description]
                    }
                  )
                )
            end

            acc
          end
        end,
        0,
        :client_status
      )
    end)
  end

  def purge_stat() do
    purge_link_table()
    purge_client_status_table()

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

  defp update_stat(key, func) do
    tval =
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

    # Telemetry
    case key do
      :down_port ->
        case tval do
          {val, _} -> :telemetry.execute([:bogatka, :links], %{down: val})
          _ -> nil
        end

      :down_tun ->
        case tval do
          {val, _} -> :telemetry.execute([:bogatka, :clients], %{down: val})
          _ -> nil
        end

      _ ->
        nil
    end

    tval
  end

  # zabbix

  def update_zabbix(host, key, value) do
    id = {host, key}
    ts = :os.system_time(:second)

    Mnesia.transaction(fn ->
      if Mnesia.wread({:tun, host}) != [] do
        Mnesia.write(Rec.zabbix(id: id, host: host, key: key, value: value, timestamp: ts))
      end
    end)
  end

  def get_zabbix(host, key) do
    case Mnesia.dirty_read({:zabbix, {host, key}}) do
      [rec] -> Rec.zabbix(rec, :value)
      _ -> nil
    end
  end

  def get_zabbix(host) do
    match(:zabbix, %{host: host})
  end

  defp delete_zabbix(host) do
    Mnesia.transaction(fn ->
      Mnesia.foldl(
        fn rec, _ ->
          tun = Rec.zabbix(rec, :host)

          if tun == host do
            Mnesia.delete_object(rec)
          end

          nil
        end,
        nil,
        :zabbix
      )
    end)
  end

  defp purge_zabbix() do
    Mnesia.transaction(fn ->
      active_tun =
        Mnesia.foldl(
          fn rec, acc ->
            Map.put(acc, Rec.tun(rec, :name), true)
          end,
          %{},
          :tun
        )

      Mnesia.foldl(
        fn rec, _ ->
          tun = Rec.zabbix(rec, :host)

          if !active_tun[tun] do
            Mnesia.delete_object(rec)
          end

          nil
        end,
        nil,
        :zabbix
      )
    end)
  end

  def update_zbx_hostgroup(zbx_hostgroup_list) do
    Mnesia.clear_table(:zbx_hostgroup)

    Mnesia.transaction(fn ->
      zbx_hostgroup_list
      |> Enum.each(fn %{"groupid" => id, "name" => name} ->
        Mnesia.write(Rec.zbx_hostgroup(name: name, hostgroupid: id))
      end)
    end)
  end

  def get_zbx_hostgroup_id_list(name_list) do
    res =
      Mnesia.transaction(fn ->
        name_list
        |> Enum.map(fn name ->
          case Mnesia.read({:zbx_hostgroup, name}) do
            [rec] -> Rec.zbx_hostgroup(rec, :hostgroupid)
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      end)

    case res do
      {:atomic, list} when is_list(list) -> list
      _ -> []
    end
  end

  # session

  def add_session(jti, params) do
    Mnesia.transaction(fn ->
      Mnesia.write({:session, jti, params, :os.system_time(:second)})
    end)
  end

  def delete_session(jti) do
    Mnesia.transaction(fn ->
      Mnesia.delete({:session, jti})
    end)
  end

  def update_session_activity(jti) do
    Mnesia.transaction(fn ->
      case Mnesia.wread({:session, jti}) do
        [] ->
          Logger.error("No session with jti = #{jti}")

        [record] ->
          Mnesia.write(Rec.session(record, activity: :os.system_time(:second)))
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

  def get_clients_number() do
    case Mnesia.transaction(fn -> Mnesia.read({:stat, :clients_number}) end) do
      {:atomic, [{:stat, :clients_number, numbers}]} -> numbers
      _ -> {0, 0}
    end
  end

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
    # |> Enum.filter(fn %{name: name} -> status[name] end)
    |> Enum.map(fn %{
                     id: id,
                     name: name,
                     description: descr,
                     address: address,
                     latitude: lat,
                     longitude: lng,
                     client_comments: client_comments
                   } = node ->
      %{
        node: node,
        id: id,
        name: name,
        description: descr,
        address: address,
        latitude: lat,
        longitude: lng,
        client_comments: client_comments,
        server: node_to_name[name_to_server[name]]
      }
      |> Map.merge(
        case status[name] do
          nil ->
            case name_to_server[name] do
              nil -> %{}
              _ -> %{alert: 0, links_number: 0}
            end

          link_list ->
            link_list
            |> reduce_link_list(node_to_name)
            |> alert()
            |> Map.put(:links_number, length(link_list))
        end
      )
    end)
  end

  def get_link_list_for_tunnel(tun_name) do
    match(:link, %{tun_id: tun_name})
  end

  defp get_link_list_for_tunnel(tun_name, :clean) do
    match_clean(:link, %{tun_id: tun_name})
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

  defp reduce_link_list(link_list, node_to_name) do
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

  defp alert(%{links_up: [], links_down: []}), do: %{alert: 0}
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

  defp alert_mes(%{links_up: [], links_down: ld}), do: {1, get_link(ld), "Устройство недоступно"}
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
      "" -> {3, [], "Соединение #{link_join(ld)} упало"}
      mes -> {2, port_list, mes}
    end
  end

  defp link_join(ld) do
    ld
    |> Enum.map(fn {lnk, srv} -> "#{lnk}@#{srv}" end)
    |> Enum.join(", ")
  end

  defp get_link(l), do: l |> Enum.map(fn {l, _} -> l end) |> Enum.uniq()
  defp get_serv(l), do: l |> Enum.map(fn {_, s} -> s end) |> Enum.uniq()

  defp get_links_str(l) do
    l |> Enum.map(fn {l, s} -> "#{l}@#{s}" end) |> Enum.join(", ")
  end

  def count(key) do
    Mnesia.transaction(fn ->
      count =
        case Mnesia.read(:counter, key) do
          [{:counter, ^key, count}] -> count
          _ -> 0
        end

      :ok = Mnesia.write(Rec.counter(key: key, count: count + 1))
      count + 1
    end)
  end
end
