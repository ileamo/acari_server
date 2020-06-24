defmodule AcariServerWeb.QRPrintLive do
  use AcariServerWeb, :live_view
  alias AcariServer.ExportManager
  alias AcariServer.ExportManager.Export

  @empty_qr %{name: nil, qr_svg: nil}

  @impl true
  def mount(_params, %{"current_user_id" => user_id, "clients_list" => ids} = _session, socket) do
    user =
      AcariServer.UserManager.get_user!(user_id, :clean)
      |> AcariServer.RepoRO.preload(:exports)

    profiles = AcariServer.ExportManager.list_exports(:type, "qr")

    current_profile =
      user.exports
      |> Enum.find(fn %{name: name, type: type} -> name == "_current" and type == "qr" end) ||
        %{profile: %{}}

    prof = current_profile.profile

    node_ids = String.split(ids, ",")

    socket =
      assign(socket,
        user: user,
        profiles: profiles,
        current_profile: current_profile,
        prof_id: nil,
        delete_prof_ack: false,
        save_prof: false,
        save_prof_show: false,
        save_prof_ack: false,
        save_prof_name: "",
        save_err: "",
        node_ids: node_ids,
        qr_list: nil,
        qr_pages: nil,
        qr_num: 0,
        qr_empty: [],
        top: prof["top"] || "8.1",
        bottom: prof["bottom"] || "8.1",
        left: prof["left"] || "13.3",
        right: prof["right"] || "13.3",
        gap: prof["gap"] || "0",
        cols: prof["cols"] || "3",
        rows: prof["rows"] || "8",
        scale: prof["scale"] || "100",
        text_up: prof["text_up"] || nil,
        border: "on"
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
      |> Enum.with_index()

    {:noreply, assign(socket, qr_list: qr_list)}
  end

  @impl true
  def handle_event("change", %{"_target" => ["text_up"]} = params, socket) do
    {:noreply, assign(socket, save_prof: false, text_up: params["textup"])}
  end

  def handle_event("change", _params, socket) do
    {:noreply, assign(socket, save_prof: false)}
  end

  def handle_event("empty", %{"idx" => idx}, socket) do
    qr_empty = socket.assigns.qr_empty
    idx = String.to_integer(idx)

    qr_empty =
      case idx in qr_empty do
        true -> qr_empty |> Enum.reject(fn x -> x == idx end)
        _ -> [idx | qr_empty] |> Enum.sort()
      end

    qr_list =
      socket.assigns.qr_list
      |> Enum.map(fn {x, _} -> x end)
      |> Enum.reject(fn %{name: name} -> is_nil(name) end)

    qr_list =
      qr_empty
      |> Enum.reduce(qr_list, fn idx, qr_list ->
        qr_list |> List.insert_at(idx, @empty_qr)
      end)

    qr_list =
      qr_list
      |> Enum.with_index()

    {:noreply, assign(socket, qr_empty: qr_empty, qr_list: qr_list)}
  end

  def handle_event("border", params, socket) do
    {:noreply, assign(socket, border: params["value"])}
  end

  def handle_event("delete_prof", _, socket) do
    {:noreply, assign(socket, delete_prof_ack: true)}
  end

  def handle_event("delete_prof_no", _, socket) do
    {:noreply, assign(socket, delete_prof_ack: false)}
  end

  def handle_event("delete_prof_yes", %{"value" => prof_id}, socket) do
    prof =
      socket.assigns.profiles
      |> Enum.find(fn %{id: id} -> id == String.to_integer(prof_id) end)

    ExportManager.delete_export(prof)

    {:noreply,
     assign(socket,
       delete_prof_ack: false,
       prof_id: nil,
       profiles: AcariServer.ExportManager.list_exports(:type, "qr")
     )}
  end

  def handle_event("change_prof", %{"prof" => "nil"}, socket) do
    {:noreply, assign(socket, prof_id: nil)}
  end

  def handle_event("change_prof", %{"prof" => prof_id}, socket) do
    prof_id = String.to_integer(prof_id)

    prof =
      (socket.assigns.profiles
       |> Enum.find(fn %{id: id} -> id == prof_id end)).profile

    socket =
      assign(socket,
        top: prof["top"] || "8.1",
        bottom: prof["bottom"] || "8.1",
        left: prof["left"] || "13.3",
        right: prof["right"] || "13.3",
        gap: prof["gap"] || "0",
        cols: prof["cols"] || "3",
        rows: prof["rows"] || "8",
        scale: prof["scale"] || "100",
        text_up: prof["text_up"] || nil
      )

    ass = socket.assigns

    {:noreply,
     assign(socket,
       prof_id: prof_id,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  def handle_event("draw", params, socket) do
    socket = validate(socket, params)

    save_profile(socket, "_current")

    ass = socket.assigns

    {:noreply,
     assign(socket,
       save_prof: true,
       prof_id: nil,
       qr_for_page: int(ass.cols) * int(ass.rows),
       svg_size: get_svg_size(ass)
     )}
  end

  def handle_event("save_prof_show", _params, socket) do
    {:noreply, assign(socket, save_prof_show: true)}
  end

  def handle_event("save", %{"profile_name" => name}, socket) do
    {show, ack, err} =
      case String.trim(name) do
        "" ->
          {true, false, "Задайте имя профиля"}

        "_current" ->
          {true, false, "Имя профиля не может быть _current"}

        name ->
          case socket.assigns.save_prof_ack do
            true ->
              save_profile(socket, name)
              {false, false, nil}

            _ ->
              case get_profile(name) do
                %Export{} ->
                  {true, true,
                   "Профиль с таким именем уже существует. Нажите еще раз СОХРАНИТЬ для обновления"}

                _ ->
                  save_profile(socket, name)
                  {false, false, nil}
              end
          end
      end

    profiles =
      case err do
        nil -> AcariServer.ExportManager.list_exports(:type, "qr")
        _ -> socket.assigns.profiles
      end

    {:noreply,
     assign(socket,
       save_prof_show: show,
       save_prof_ack: ack,
       save_err: err,
       save_prof_name: name,
       profiles: profiles
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

  defp get_profile(name, user_id \\ nil) do
    ExportManager.get_export_by("qr", name, user_id)
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
      text_up: ass.text_up
    }

    attrs = %{user_id: ass.user.id, name: name, type: "qr", profile: profile}

    user_id = (name == "_current" && nil) || ass.user.id

    case get_profile(name, user_id) do
      %Export{} = export -> ExportManager.update_export(export, attrs)
      _ -> ExportManager.create_export(attrs)
    end
  end
end
