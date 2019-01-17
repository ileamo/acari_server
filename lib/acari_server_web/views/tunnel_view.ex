defmodule AcariServerWeb.TunnelView do
  use AcariServerWeb, :view

  def get_tunnel_list() do
    tuns =
      :ets.tab2list(:tuns)
      |> Enum.map(fn {name, _, _, state} -> {name, state} end)
      |> Enum.into(%{})

    AcariServer.NodeManager.list_nodes_wo_preload()
    |> Enum.map(fn %{name: n, description: d} -> %{name: n, description: d} end)
    |> Enum.map(fn %{name: name} = m -> Map.merge(m, get_sslinks(tuns[name])) end)
    |> Enum.map(fn
      %{links_up: nil} = m -> Map.put(m, :alert, 1)
      %{links_down: nil} = m -> Map.put(m, :alert, 3)
      m -> Map.put(m, :alert, 2)
    end)
  end

  defp get_sslinks(nil), do: %{links_up: nil, links_down: nil}

  defp get_sslinks(tun_state) do
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
end
