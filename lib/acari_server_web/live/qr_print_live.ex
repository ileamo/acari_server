defmodule AcariServerWeb.QRPrintLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(_params, %{"clients_list" => ids} = _session, socket) do
    IO.puts("MOUNT")
    node_ids = String.split(ids, ",")

    socket =
      assign(socket,
        node_ids: node_ids,
        qr_list: nil,
        qr_num: 0,
        top: "15",
        bottom: "15",
        left: "15",
        right: "15",
        gap: "1",
        cols: "3",
        rows: "8",
        scale: "100",
        text_up: nil,
      )

    ass = socket.assigns

    send(self(), :after_mount)

    {:ok,
     assign(socket,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  @impl true
  def handle_info(:after_mount, socket) do
    IO.puts("After MOUNT")
    url =
      AcariServer.SysConfigManager.get_conf_by_key("system.url.mobile") ||
        "http://localhost"


    qr_list =
      socket.assigns.node_ids
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

    {:noreply, assign(socket, qr_list: qr_list)}
  end

  @impl true
  def handle_event("draw", params, socket) do
    IO.inspect(params)
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
    rows = int(ass.rows)
    cols = int(ass.cols)
    top = float(ass.top)
    bottom = float(ass.bottom)
    left = float(ass.left)
    right = float(ass.right)
    gap =   float(ass.gap)

    min(
      (297 - top - bottom - gap * (rows - 1) ) / rows,
      (210 - left - right - gap * (cols - 1)) / cols
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
      int(ass, :rows, params["rows"]),
      int(ass, :scale, params["scale"]),
      {:text_up, params["text_up"]}
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
