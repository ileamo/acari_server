defmodule AcariServerWeb.SysConfigLive.StringComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  require AcariServer.SysConfig
  AcariServer.SysConfig.component_common()

  def handle_event("input_focus", _params, socket) do
    {:noreply, assign(socket, color: "primary")}
  end

  def handle_event("input_blur", params, socket) do
    {:ok, %{value: value}} =
      SysConfigManager.insert_or_update_sys_config(%{
        key: socket.assigns.key,
        value: params["value"]
      })

    {:noreply, assign(socket, value: value, color: "dark")}
  end
end
