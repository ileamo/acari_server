defmodule AcariServerWeb.SysConfigLive.Index do
  use AcariServerWeb, :live_view

  alias AcariServer.SysConfigManager
  alias AcariServer.SysConfigManager.SysConfig

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :sysconfigs, fetch_sysconfigs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Sys config")
    |> assign(:sys_config, SysConfigManager.get_sys_config!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Sys config")
    |> assign(:sys_config, %SysConfig{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sysconfigs")
    |> assign(:sys_config, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sys_config = SysConfigManager.get_sys_config!(id)
    {:ok, _} = SysConfigManager.delete_sys_config(sys_config)

    {:noreply, assign(socket, :sysconfigs, fetch_sysconfigs())}
  end

  defp fetch_sysconfigs do
    SysConfigManager.list_sysconfigs()
  end
end
