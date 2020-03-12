defmodule AcariServerWeb.RoomChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  alias AcariServer.ChatManager
  alias AcariServer.ChatManager.Chat

  require Logger

  def join("room:lobby", _message, socket) do
    user = AcariServer.UserManager.get_user(socket.assigns[:current_user_id])
    {:ok, assign(socket, :user, user)}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  intercept(["link_event_mes"])

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

  # Chat

  def handle_in("shout", payload, socket) do
    user = socket.assigns[:user]

    {:ok, %{updated_at: nt}} =
      Chat.changeset(
        %Chat{},
        payload |> Map.put("user_id", user.id)
      )
      |> AcariServer.Repo.insert()

    broadcast_msg_html = create_message(user.username, payload["message"], db_time_to_local(nt))

    msg_html = change_message_color(broadcast_msg_html, "text-secondary")
    broadcast_from(socket, "shout", %{"message" => broadcast_msg_html})
    push(socket, "shout", %{"message" => msg_html})
    {:noreply, socket}
  end

  def handle_in("init_chat", _payload, socket) do
    user = socket.assigns[:user]

    ChatManager.get_chat_messages()
    |> Enum.each(fn %{user: %{id: user_id, username: username}, message: message, updated_at: nt} ->
      msg_html = create_message(username, message, db_time_to_local(nt, true))

      msg_html =
        if user.id == user_id do
          change_message_color(msg_html, "text-secondary")
        else
          msg_html
        end

      push(socket, "shout", %{"message" => msg_html})
    end)

    {:noreply, socket}
  end

  def handle_in(event, _payload, socket) do
    Logger.error("Channel room: bad event: #{inspect(event)}")
    {:noreply, socket}
  end

  defp create_message(username, message, timestamp) do
    """
    <strong>#{timestamp} #{username}:</strong> #{message}
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
