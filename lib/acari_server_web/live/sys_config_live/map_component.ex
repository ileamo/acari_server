defmodule AcariServerWeb.SysConfigLive.MapComponent do
  use Phoenix.LiveComponent
  alias AcariServer.SysConfigManager

  require AcariServer.SysConfig
  AcariServer.SysConfig.component_common(%{show_map: false})

  def handle_event("show_map", _params, socket) do
    {:noreply, assign(socket, show_map: !socket.assigns.show_map)}
  end

  def handle_event("new", %{"new_global" => name}, socket) do
    ass =
      case String.trim(name) do
        "" ->
          [name_error: ""]

        name ->
          cond do
            socket.assigns.value["#{socket.assigns.key}.#{name}"] ->
              [name_error: "Переменная уже существует"]

            String.match?(name, ~r|^[a-z]\w*$|) ->
              [
                value: Map.put(socket.assigns.value, "#{socket.assigns.key}.#{name}", ""),
                name_error: ""
              ]

            String.match?(name, ~r|^#{socket.assigns.key}\.|) ->
              [name_error: "Имя переменной должно быть без префикса #{socket.assigns.key}"]

            String.match?(name, ~r|^[^a-z]|) ->
              [name_error: "Имя переменной должно начинаться со строчной латинской буквы"]

            true ->
              [
                name_error:
                  "Имя переменной должно состоять из латинских букв, цифр и знака подчеркивания"
              ]
          end
      end

    {:noreply, assign(socket, [{:new_value, name} | ass])}
  end

  def handle_event("delete", %{"name" => name}, socket) do
    case Map.pop(socket.assigns.value, name) do
      {nil, _} ->
        {:noreply, socket}

      {val, map} ->
        del = [{name, val} | socket.assigns.delete_list]

        {:noreply, assign(socket, value: map, delete_list: del)}
    end
  end

  def handle_event("undelete", _, socket) do
    case socket.assigns.delete_list do
      [{name, val} | del] ->
        {:noreply,
         assign(socket, value: Map.put(socket.assigns.value, name, val), delete_list: del)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("input_blur", %{"name" => name, "value" => value}, socket) do
    {:noreply, assign(socket, value: Map.put(socket.assigns.value, name, value))}
  end

  def handle_event("save", params, socket) do
    socket.assigns.delete_list
    |> Enum.each(fn {name, _} -> SysConfigManager.delete_sys_config_by_key(name) end)

    params
    |> Enum.each(fn {name, value} ->
      SysConfigManager.insert_or_update_sys_config(%{
        key: name,
        value: value
      })
    end)

    sysconfig = SysConfigManager.get_sysconfigs_by_prefix(socket.assigns.key)


    {:noreply, assign(socket, value: sysconfig, delete_list: [], new_value: "", name_error: "")}
  end

  def handle_event(event, params, socket) do
    {:noreply, socket}
  end

  def show_vars(value) do
    case Jason.encode(value) do
      {:ok, json} -> json
      _ -> inspect(value)
    end
  end
end
