defmodule AcariServer.Mnesia.Attr do
  def server(), do: [:name, :opt]
  def tun(), do: [:name, :server_id, :state, :opt]
  def link(), do: [:id, :name, :server_id, :tun_id, :up, :state, :opt]
  def event(), do: [:id, :timestamp, :level, :header, :text]

  def table_list(), do: [:server, :tun, :link, :event]

  def pattern(tab, field_pattern) do
    mk_record(tab, field_pattern, :_)
  end

  def mk_record(tab, fields_map, filler \\ nil) do
    [
      tab
      | apply(__MODULE__, tab, [])
        |> Enum.map(fn field -> fields_map[field] || filler end)
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

  def init() do
    Mnesia.start()

    node_list = get_node_list()

    Mnesia.change_config(:extra_db_nodes, node_list)
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
        ram_copies: node_list
      )
    end

    update_servers_list(node_list)
  end

  def update_servers_list(node_list) do
    Mnesia.transaction(fn ->
      existing_servers = Mnesia.all_keys(:server)
      new = node_list -- existing_servers
      old = existing_servers -- node_list
      old |> Enum.each(fn item -> Mnesia.delete({:server, item}) end)
      new |> Enum.each(fn item -> Mnesia.write(Rec.server(name: item)) end)
    end)
  end

  def add_tunnel(kl) do
    name = kl |> Keyword.get(:name)

    case Mnesia.transaction(fn ->
           case Mnesia.wread({:tun, name}) do
             [] ->
               :ok = Mnesia.write(mk_record(:tun, kl))
               kl |> Keyword.get(:server_id)

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

        node
    end
  end

  def update_tun_inventoty(name, data) do
    update_tun_state(name, :inventory, data)
  end

  def update_tun_telemetry(name, data) do
    update_tun_state(name, :telemetry, data)
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
            |> AcariServer.ServerManager.get_server_name_by_system_name()
        })

      _ ->
        nil
    end
  end

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

    case up do
      true -> delete_event(id)
      _ -> update_event(%{id: id, level: 3, header: tun, text: "#{name}: упало"})
    end
  end

  def update_event(ev) do
    ev = ev |> Map.put(:timestamp, :os.system_time(:second))
    Mnesia.transaction(fn ->
      Mnesia.write(mk_record(:event, ev))
    end)
  end

  def delete_event(id) do
    Mnesia.transaction(fn ->
      Mnesia.delete({:event, id})
    end)
  end

  def get_tunnel_list(nodes) do
    node_to_name = AcariServer.ServerManager.get_node_to_name_map()

    name_to_server =
      match(:tun)
      |> Enum.map(fn %{name: name, server_id: server} -> {name, server} end)
      |> Enum.into(%{})

    status =
      match(:link)
      |> link_list_to_map()

    nodes
    |> Enum.map(fn %{name: name, description: descr} ->
      %{name: name, description: descr, server: node_to_name[name_to_server[name]]}
      |> Map.merge(
        case status[name] do
          nil -> %{}
          link_list -> link_list |> reduce_link_list(node_to_name)
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
    |> alert()
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

  defp get_link(l), do: l |> Enum.map(fn {l, _} -> l end) |> Enum.uniq()
  defp get_serv(l), do: l |> Enum.map(fn {_, s} -> s end) |> Enum.uniq()

  defp get_links_str(l) do
    l |> Enum.map(fn {l, s} -> "#{l}@#{s}" end) |> Enum.join(", ")
  end

  defp get_node_list() do
    AcariServer.ServerManager.list_servers()
    |> Enum.map(fn %{system_name: name} -> name |> String.to_atom() end)
  end
end
