defmodule AcariServerWeb.SysConfigLive do
  use AcariServerWeb, :live_view

  alias AcariServer.SysConfigManager
  alias AcariServer.SysConfigManager.Schema

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, sysconfig: fetch_sysconfigs())}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp fetch_sysconfigs do
    sysconfig =
      SysConfigManager.list_sysconfigs()
      |> Enum.map(fn %{key: key, value: value} -> {key, value} end)
      |> Enum.into(%{})

    Schema.get()
    |> Enum.map(fn sch = %{key: key} -> sch |> Map.put(:value, sysconfig[key]) end)
  end
end
