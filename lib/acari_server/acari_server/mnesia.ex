defmodule AcariServer.Mnesia do
  alias :mnesia, as: Mnesia

  def init() do
    Mnesia.start()

    node_list =
      AcariServer.ServerManager.list_servers()
      |> Enum.map(fn %{name: name} -> name end)

    Mnesia.change_config(:extra_db_nodes, node_list)
  end
end
