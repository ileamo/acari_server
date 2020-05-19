defmodule AcariServerWeb.SysConfigLive do
  use AcariServerWeb, :live_view

  alias AcariServer.SysConfigManager
  #alias AcariServer.SysConfigManager.SysConfig

  @impl true
  def mount(_params, _session, socket) do
    IO.inspect(socket.assigns, label: "MOUNT")
    {:ok, assign(socket, sysconfigs: fetch_sysconfigs(), query: "")}
  end


  @impl true
  def handle_event(event, params, socket) do
    IO.inspect({event, params})

    {:noreply, assign(socket, :sysconfigs, fetch_sysconfigs())}
  end

  defp fetch_sysconfigs do
    SysConfigManager.list_sysconfigs()
  end
end
