defmodule AcariServerWeb.RoomChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  alias AcariServer.ChatManager
  alias AcariServer.Presence

  require Logger

  def join("room:lobby", _message, socket) do
    user = AcariServer.UserManager.get_user(socket.assigns[:current_user_id])
    send(self(), :after_join)
    {:ok, assign(socket, :user, user) |> assign(:conn, socket.assigns[:conn])}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(
        socket,
        socket.assigns.user.id,
        %{
          username: socket.assigns.user.username,
          online_at: :os.system_time(:second),
          server: Node.self() |> AcariServer.Mnesia.get_server_name_by_system_name(),
          conn: socket.assigns.conn
        }
      )

    broadcast_from(socket, "shout", %{"chat_users" => get_chat_users()})
    broadcast_sessions()
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    Task.start(fn ->
      Process.sleep(1000)
      broadcast_from(socket, "shout", %{"chat_users" => get_chat_users()})
      broadcast_sessions()
    end)

    :ok
  end

  defp broadcast_sessions() do
    sessions_html = Phoenix.View.render_to_string(AcariServerWeb.PageView, "session.html", [])

    AcariServerWeb.Endpoint.broadcast!("room:lobby", "link_event", %{
      sessions: sessions_html
    })
  end

  intercept(["link_event_mes", "presence_diff"])

  def handle_out("presence_diff", _params, socket) do
    {:noreply, socket}
  end

  def handle_out("link_event_mes", %{mes_list: mes_list}, socket) do
    mes_list =
      mes_list
      |> AcariServer.Mnesia.get_client_status(socket.assigns.current_user_id)

    events =
      mes_list
      |> Enum.map(fn %{name: name, opts: %{level: level}} -> %{name: name, level: level} end)

    mes_html =
      Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "messages.html", mes_list: mes_list)

    push(socket, "link_event_mes", %{
      num_of_mes: mes_list |> length(),
      messages: mes_html,
      events: events
    })

    {:noreply, socket}
  end

  def handle_out(event, _params, socket) do
    Logger.error("Channel room: bad output event: #{inspect(event)}")
    {:noreply, socket}
  end

  # Chat

  def handle_in("shout", payload, socket) do
    user = socket.assigns[:user]

    {:ok, %{id: id, inserted_at: nt}} =
      ChatManager.create_chat(payload |> Map.put("user_id", user.id))

    broadcast_msg_html = create_message(user.username, payload["message"], db_time_to_local(nt))

    msg_html = change_message_color(broadcast_msg_html, "text-secondary")
    chat_users = get_chat_users()

    broadcast_from(socket, "shout", %{
      "message" => broadcast_msg_html,
      "chat_users" => chat_users,
      "chat_msg_id" => id,
      "chat_msg_timestamp" => nt
    })

    push(socket, "shout", %{
      "message" => msg_html,
      "chat_users" => chat_users,
      "chat_msg_id" => id,
      "chat_msg_timestamp" => nt
    })

    {:noreply, socket}
  end

  def handle_in("init_chat", _payload, socket) do
    push_chat_messages(socket)
    {:noreply, socket}
  end

  def handle_in("get_about_system", _payload, socket) do
    msg_html = Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "about_system.html", [])
    push(socket, "about_system", %{"message" => msg_html})
    {:noreply, socket}
  end

  def handle_in("get_chat_msgs", payload, socket) do
    with iso_datetime when is_binary(iso_datetime) <- payload["timestamp"],
         {:ok, ndt} <- NaiveDateTime.from_iso8601(iso_datetime) do
      push_chat_messages(socket, ndt, payload["id"])
    else
      _ -> push_chat_messages(socket)
    end

    {:noreply, socket}
  end

  def handle_in(event, _payload, socket) do
    Logger.error("Channel room: bad input event: #{inspect(event)}")
    {:noreply, socket}
  end

  defp push_chat_messages(socket, ndt \\ nil, id \\ nil) do
    user = socket.assigns[:user]
    chat_users = get_chat_users()

    if (chat_messages = ChatManager.get_chat_messages(ndt, id)) != [] do
      {chat_msg_id, chat_msg_timestamp} =
        case List.last(chat_messages) do
          %{id: id, inserted_at: tm} -> {id, tm}
          _ -> {0, 0}
        end

      msg_html =
        chat_messages
        |> Enum.map(fn %{
                         user: %{id: user_id, username: username},
                         message: message,
                         updated_at: nt
                       } ->
          msg_html = create_message(username, message, db_time_to_local(nt, true))

          if user.id == user_id do
            change_message_color(msg_html, "text-secondary")
          else
            msg_html
          end
        end)
        |> Enum.join()

      push(socket, "shout", %{
        "message" => msg_html,
        "chat_users" => chat_users,
        "chat_msg_id" => chat_msg_id,
        "chat_msg_timestamp" => chat_msg_timestamp
      })
    end
  end

  defp get_chat_users() do
    get_sorted_presence()
    |> Enum.map(fn %{username: u} -> u end)
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  def get_sessions() do
    get_sorted_presence()
  end

  defp get_sorted_presence() do
    Presence.list("room:lobby")
    |> Enum.flat_map(fn {id, %{metas: list}} ->
      list
      # TODO Убрать после 1.1.15
      |> Enum.map(fn
        %{username: _} = item -> item
        _ -> %{username: id, online_at: 1, server: "unknown", conn: %{}}
      end)

      #
    end)
    |> Enum.sort_by(fn %{online_at: t} -> t end, &>=/2)
  end

  defp create_message(username, message, timestamp) do
    """
    <div>
      <strong>#{timestamp} #{username}:</strong> #{message}
    </div>
    """
  end

  defp change_message_color(mes, color_class) do
    "<span class='#{color_class}'>#{mes}</span>"
  end

  defp db_time_to_local(time, is_date? \\ false) do
    {{year, mes, d}, {h, m, _s}} =
      time
      |> NaiveDateTime.to_erl()
      |> :erlang.universaltime_to_localtime()

    if is_date? and
         :gt ==
           NaiveDateTime.compare(NaiveDateTime.add(NaiveDateTime.utc_now(), -60 * 60 * 24), time) do
      :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B", [year, mes, d, h, m])
    else
      :io_lib.format("~2..0B:~2..0B", [h, m])
    end
  end
end
