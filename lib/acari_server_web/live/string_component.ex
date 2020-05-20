defmodule AcariServerWeb.SysConfigLive.StringComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  @impl true
  def update(assigns, socket) do
    {:ok,
     assign(socket,
       key: assigns.id,
       name: assigns.config.name,
       value: assigns.config.value,
       saved_value: assigns.config.value,
       color: "dark"
     )}
  end

  @impl true
  def handle_event("input_focus", _params, socket) do
    {:noreply, assign(socket, color: "primary")}
  end

  def handle_event("input_blur", params, socket) do
    color = if params["value"] == socket.assigns.saved_value, do: "dark", else: "primary"

    {:noreply, assign(socket, color: color, value: params["value"])}
  end

  def handle_event("save", _params, socket) do
    {:ok, %{value: value}} =
      SysConfigManager.insert_or_update_sys_config(%{
        key: socket.assigns.key,
        value: socket.assigns.value
      })

    {:noreply, assign(socket, saved_value: value, color: "dark")}
  end

  def handle_event(event, params, socket) do
    IO.inspect({event, params, socket.assigns}, label: "COMPONENT")

    {:noreply, socket}
  end
end
