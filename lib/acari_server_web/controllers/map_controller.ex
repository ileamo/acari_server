defmodule AcariServerWeb.MapController do
  use AcariServerWeb, :controller

  def index(conn, params) do
    nodes =
      case params["group_id"] do
        "" -> AcariServer.NodeManager.list_nodes_wo_preload()
        n -> AcariServer.GroupManager.get_group!(n).nodes
      end
      |> Enum.map(fn
        %{latitude: lat, longitude: lng, name: name, description: descr} when is_float(lat) and is_float(lng) ->
          %{lat: lat, lng: lng, title: "<a href='/tunnel/#{name}'>#{name}</a><br/>#{descr}"}

        _ ->
          %{lat: 55.777594, lng: 37.737926}
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
          markers: markers_json,
          bounds: bounds_json,
          center_lat: center_lat,
          center_lng: center_lng
        )
    end
  end
end
