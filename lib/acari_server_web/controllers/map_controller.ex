defmodule AcariServerWeb.MapController do
  use AcariServerWeb, :controller

  def index(%{assigns: %{current_user: %{is_admin: true}}} = conn, params) do
    {nodes, group_name} =
      case params["group_id"] || "" do
        "" ->
          {AcariServer.NodeManager.list_nodes_wo_preload(), "Все"}

        n ->
          group = AcariServer.GroupManager.get_group!(n)
          {group.nodes, group.name}
      end

    index(conn, params, nodes, group_name)
  end

  def index(%{assigns: %{current_user: user}} = conn, params) do
    groups =
      user
      |> AcariServer.RepoRO.preload(groups: :nodes)
      |> Map.get(:groups)

    {nodes, group_name} =
      case params["group_id"] || "" do
        "" ->
          nodes =
            groups
            |> Enum.map(fn %{nodes: nodes} -> nodes end)
            |> List.flatten()
            |> Enum.uniq_by(fn %{id: id} -> id end)

          {nodes, "Все"}

        n ->
          group = AcariServer.GroupManager.get_group!(n)
          {group.nodes, group.name}
      end

    index(conn, params, nodes, group_name, groups)
  end

  def index(conn, params, nodes, group_name, groups \\ nil) do
    nodes =
      nodes
      |> Enum.reject(fn %{lock: lock} -> lock end)
      |> AcariServer.Mnesia.get_tunnel_list()
      |> Enum.map(fn
        %{latitude: lat, longitude: lng, name: name, description: descr} = node ->
          %{
            name: name,
            lat: lat || 55.777594,
            lng: lng || 37.737926,
            alert: node[:alert] || 0,
            title: "<a href='/tunnel/#{name}'>#{name}</a><br/>#{descr}"
          }
      end)

    case nodes do
      [] ->
        render(conn, "index0.html",
          center_lat: 55.777594,
          center_lng: 37.737926
        )

      nodes ->
        {%{lat: lat_min}, %{lat: lat_max}} = Enum.min_max_by(nodes, fn %{lat: lat} -> lat end)
        center_lat = (lat_max + lat_max) / 2

        {%{lng: lng_min}, %{lng: lng_max}} = Enum.min_max_by(nodes, fn %{lng: lng} -> lng end)
        center_lng = (lng_max + lng_min) / 2

        bounds = [[lat_max, lng_max], [lat_min, lng_min]]

        {:ok, markers_json} = Jason.encode(nodes)
        {:ok, bounds_json} = Jason.encode(bounds)

        render(conn, "index.html",
          group_id: params["group_id"] || "",
          group_name: group_name,
          groups: groups,
          markers: markers_json,
          bounds: bounds_json,
          center_lat: center_lat,
          center_lng: center_lng
        )
    end
  end
end
