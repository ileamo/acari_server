defmodule AcariServerWeb.QRPrintLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(_params, %{"clients_list" => ids} = _session, socket) do
    url =
      AcariServer.SysConfigManager.get_conf_by_key("system.url.mobile") ||
        "http://localhost"

    qr_list =
      String.split(ids, ",")
      |> Enum.filter(fn x ->
        case Integer.parse(x) do
          {_, ""} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn id -> AcariServer.NodeManager.get_node_hash(id) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn %{hash: hash, name: name, description: description, address: address} ->
        %{
          qr_svg: (url <> "/client/" <> hash) |> EQRCode.encode() |> EQRCode.svg(width: 200),
          name: name,
          description: description,
          address: address
        }
      end)

    socket =
      assign(socket,
        qr_list: qr_list,
        qr_num: length(qr_list),
        top: "15",
        bottom: "15",
        left: "15",
        right: "15",
        gap: "1",
        cols: "3",
        rows: "8"
      )

    ass = socket.assigns

    {:ok,
     assign(socket,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  @impl true
  def handle_event("draw", params, socket) do
    socket = validate(socket, params)
    ass = socket.assigns

    {:noreply,
     assign(socket,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp get_svg_size(ass) do
    min(
      (297 - float(ass.top) - float(ass.bottom)) / int(ass.rows) - 5,
      (210 - float(ass.left) - float(ass.right)) / int(ass.cols) - 2
    )
  end

  defp validate(socket, params) do
    ass = socket.assigns

    params = [
      float(ass, :top, params["top"]),
      float(ass, :bottom, params["bottom"]),
      float(ass, :left, params["left"]),
      float(ass, :right, params["right"]),
      float(ass, :gap, params["gap"]),
      int(ass, :cols, params["cols"]),
      int(ass, :rows, params["rows"])
    ]

    assign(socket, params)
  end

  defp int(val) do
    case Integer.parse(String.trim(val)) do
      {n, ""} -> n
      _ -> 0
    end
  end

  defp float(val) do
    case Float.parse(String.trim(val)) do
      {n, ""} -> n
      _ -> 0
    end
  end

  defp int(ass, tag, val) do
    {tag,
     case Integer.parse(String.trim(val)) do
       {n, ""} -> to_string(n)
       _ -> ass[tag] <> " "
     end}
  end

  defp float(ass, tag, val) do
    {tag,
     case Float.parse(String.trim(val)) do
       {n, ""} -> to_string(n)
       _ -> ass[tag] <> " "
     end}
  end
end
