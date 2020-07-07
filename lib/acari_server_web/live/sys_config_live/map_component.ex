defmodule AcariServerWeb.SysConfigLive.MapComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  require AcariServer.SysConfig
  AcariServer.SysConfig.component_common()

  def handle_event("show_map", _params, socket) do
    {:noreply, assign(socket, show_map: !socket.assigns.show_map)}
  end

  def handle_event("new", %{"new_global" => name}, socket) do
    {:noreply, assign(socket, value: Map.put(socket.assigns.value, "#{socket.assigns.key}.#{name}", ""))}
  end

  def handle_event(event, params, socket) do
    IO.inspect({event, params, socket.assigns})
    {:noreply, socket}
  end
end
