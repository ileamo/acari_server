defmodule AcariServer.Mnesia.Attr do
  def server(), do: [:name, :opt]
  def tun(), do: [:name, :server_id]
  def link(), do: [:id, :name, :server_id, :tun_id, :up]

  def table_list(), do: [:server, :tun, :link]

  def pattern(tab, field_pattern) do
    [
      tab
      | apply(__MODULE__, tab, [])
        |> Enum.map(fn field -> field_pattern[field] || :_ end)
    ]
    |> List.to_tuple()
  end

  def record_to_map(rec) do
    [tab | fields] = Tuple.to_list(rec)

    Enum.zip(apply(__MODULE__, tab, []), fields)
    |> Enum.into(%{})
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

  def tun_write(kl) do
    Mnesia.transaction(fn -> Mnesia.write(Rec.tun(kl)) end)
  end

  def update_link(name, tun, up) do
    node = node()
    id = {name, tun, node}

    Mnesia.transaction(fn ->
      Mnesia.write(Rec.link(id: id, name: name, tun_id: tun, server_id: node, up: up))
    end)
  end

  def get_tunnel_list(nodes) do
    status =
      match(:link)
      |> link_list_to_map()

    nodes
    |> Enum.map(fn %{name: name, description: descr} ->
      %{name: name, description: descr}
      |> Map.merge(status[name])
    end)
  end

  def match(tab, field_pattern \\ %{}) do
    {:atomic, rec_list} =
      Mnesia.transaction(fn ->
        Mnesia.match_object(Attr.pattern(tab, field_pattern))
      end)

    rec_list |> Enum.map(fn r -> r |> Attr.record_to_map() end)
  end

  def link_list_to_map(link_list) do
    node_to_name = AcariServer.ServerManager.get_node_to_name_map()

    link_list
    |> Enum.reduce(%{}, fn %{tun_id: tun_name} = link, acc ->
      new_link = %{
        name: link.name,
        server: node_to_name[link.server_id] || link.server_id,
        up: link.up
      }

      new_link_list =
        case acc[tun_name] do
          nil -> [new_link]
          list when is_list(list) -> [new_link | list]
        end

      acc |> Map.put(tun_name, new_link_list)
    end)
    |> Enum.map(fn {tun_name, link_list} ->
      {tun_name, link_list |> reduce_link_list()}
    end)
    |> Enum.into(%{})
  end

  defp reduce_link_list(link_list) do
    link_list
    |> Enum.reduce(
      %{links_up: [], links_down: []},
      fn %{name: name, server: server, up: up}, %{links_up: lu, links_down: ld} ->
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