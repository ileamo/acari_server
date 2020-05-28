defmodule AcariServerWeb.SysConfigLive.BooleanComponent do
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
end
