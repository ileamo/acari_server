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
    |> Enum.map(fn
      sch = %{type: :map, key: key} -> sch |> Map.put(:value, get_map(sysconfig, key))
      sch = %{key: key} -> sch |> Map.put(:value, sysconfig[key])
    end)
  end

  defp get_map(sysconfig, key) do
    sysconfig
    |> Enum.filter(fn {k, _} -> String.match?(k, ~r/^#{key}\..+/) end)
    |> Enum.into(%{})
  end
end
