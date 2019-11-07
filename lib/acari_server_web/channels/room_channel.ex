defmodule AcariServerWeb.RoomChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  intercept(["link_event_mes"])

  def handle_out("link_event_mes", %{mes_list: mes_list}, socket) do
    mes_list = mes_list |> AcariServer.Mnesia.get_client_status(socket.assigns.current_user_id)

    mes_html =
      Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "messages.html", mes_list: mes_list)

    push(socket, "link_event_mes", %{num_of_mes: mes_list |> length(), messages: mes_html})
    {:noreply, socket}
  end
end
