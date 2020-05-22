defmodule AcariServerWeb.SysConfigLive.SelectComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  require AcariServer.SysConfig
  AcariServer.SysConfig.component_common()

  def handle_event("check", params, socket) do
    {:ok, %{value: value}} =
      SysConfigManager.insert_or_update_sys_config(%{
        key: socket.assigns.key,
        value: params["value"]
      })

    {:noreply, assign(socket, value: value)}
  end

  def handle_event("select", params, socket) do
    {:ok, %{value: value}} =
      SysConfigManager.insert_or_update_sys_config(%{
        key: socket.assigns.key,
        value: params["value"]
      })

    {:noreply, assign(socket, value: value)}
  end



  def handle_event(event, params, socket) do
    IO.inspect({event, params, socket.assigns}, label: "COMPONENT")

    {:noreply, socket}
  end
end
