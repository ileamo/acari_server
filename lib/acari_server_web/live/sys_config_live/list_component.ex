defmodule AcariServerWeb.SysConfigLive.ListComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  require AcariServer.SysConfig

  AcariServer.SysConfig.component_common(
    %{show_list: false},
    &decode_value/1
  )

  def decode_value(val) when is_binary(val) do
    case Jason.decode(val) do
      {:ok, list} when is_list(list) -> list |> Enum.sort()
      _ -> []
    end
  end

  def decode_value(_), do: []

  def handle_event("show_list", _params, socket) do
    {:noreply, assign(socket, show_list: !socket.assigns.show_list)}
  end

  def handle_event("new", %{"new_element" => val}, socket) do
    {:noreply, assign(socket, value: [val | socket.assigns.value])}
  end

  def handle_event("delete", %{"name" => idx}, socket) do
    case List.pop_at(socket.assigns.value, String.to_integer(idx)) do
      {nil, _} ->
        {:noreply, socket}

      {val, list} ->
        del = [val | socket.assigns.delete_list]

        {:noreply, assign(socket, value: list, delete_list: del)}
    end
  end

  def handle_event("undelete", _, socket) do
    case socket.assigns.delete_list do
      [val | del] ->
        {:noreply,
         assign(socket, value: [val | socket.assigns.value], delete_list: del)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("input_blur", %{"name" => idx, "value" => value}, socket) do
    {:noreply, assign(socket, value: socket.assigns.value |> List.replace_at(String.to_integer(idx), value))}
  end

  def handle_event("save", params, socket) do
    val = params
    |> Enum.map(fn {_, val} -> val end)
    {:ok, json} = Jason.encode(val)
    {:ok, %{value: value}} =
      SysConfigManager.insert_or_update_sys_config(%{
        key: socket.assigns.key,
        value: json
      })

    {:noreply, assign(socket, value: decode_value(value))}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  def show_vars(value) do
    case Jason.encode(value) do
      {:ok, json} -> json
      _ -> inspect(value)
    end
  end
end
