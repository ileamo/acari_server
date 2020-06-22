defmodule AcariServerWeb.QRPrintLive do
  use AcariServerWeb, :live_view
  alias AcariServer.ExportManager
  alias AcariServer.ExportManager.Export

  @impl true
  def mount(_params, %{"current_user_id" => user_id, "clients_list" => ids} = _session, socket) do

    user =
      AcariServer.UserManager.get_user!(user_id, :clean)
      |> AcariServer.RepoRO.preload(:exports)

    current_profile =
      user.exports
      |> Enum.find(fn %{name: name, type: type} -> name == "_current" and type == "qr" end) ||
        %{profile: %{}}

    prof = current_profile.profile


    node_ids = String.split(ids, ",")

    socket =
      assign(socket,
        user: user,
        current_profile: current_profile,
        save_prof: false,
        save_err: "",
        node_ids: node_ids,
        qr_list: nil,
        qr_num: 0,
        top: prof["top"] || "15",
        bottom: prof["bottom"] || "15",
        left: prof["left"] || "15",
        right: prof["right"] || "15",
        gap: prof["gap"] || "1",
        cols: prof["cols"] || "3",
        rows: prof["rows"] || "8",
        scale: prof["scale"] || "100",
        text_up: prof["text_up"] || nil,
        border: prof["border"] || "on"
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
  def handle_event("change", _params, socket) do
    {:noreply, assign(socket, save_prof: false)}
  end

  def handle_event("draw", params, socket) do
    socket = validate(socket, params)

    save_profile(socket, "_current")

    ass = socket.assigns

    {:noreply,
     assign(socket,
       save_prof: true,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  def handle_event("save", %{"profile_name" => name}, socket) do

    {status, err} =
      case String.trim(name) do
        "" ->
          {true, "Задайте имя профиля"}

        "_current" ->
          {true, "Имя профиля не может быть _current"}

        name ->
          case get_profile(socket.assigns.user.id, name) do
            %Export{} -> {true, "Профиль с таким именем уже существует"}
            _ -> {false, nil}
          end
      end

    {:noreply, assign(socket, save_prof: status, save_err: err)}
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
    gap = float(ass.gap)

    min(
      (297 - top - bottom - gap * (rows - 1)) / rows,
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
      {:text_up, params["text_up"]},
      {:border, params["border"]}
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

  defp get_profile(user_id, name) do
    ExportManager.get_export_by(user_id, "qr", name)
  end

  defp save_profile(socket, name) do
    ass = socket.assigns

    profile = %{
      top: ass.top,
      bottom: ass.bottom,
      left: ass.left,
      right: ass.right,
      gap: ass.gap,
      cols: ass.cols,
      rows: ass.rows,
      scale: ass.scale,
      border: ass.border
    }

    attrs = %{user_id: ass.user.id, name: name, type: "qr", profile: profile}

    case  get_profile(ass.user.id, name) do
      %Export{} = export -> ExportManager.update_export(export, attrs)
      _ -> ExportManager.create_export(attrs)
    end
  end
end
