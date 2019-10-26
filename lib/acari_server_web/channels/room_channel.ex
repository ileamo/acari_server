defmodule AcariServerWeb.RoomChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
