defmodule AcariServerWeb.ExportLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(_params, %{"current_user_id" => user_id} = _session, socket) do
    user = AcariServer.UserManager.get_user!(user_id, :clean)

    groups =
      AcariServer.GroupManager.list_groups(user)
      |> Enum.map(fn %{id: id, name: name} -> {to_string(id), name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    [{group_id, _} | _] = groups

    classes =
      AcariServer.ScriptManager.list_scripts()
      |> Enum.map(fn %{id: id, name: name} -> {id, name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    left_scripts =
      (AcariServer.TemplateManager.list_templates("client") ++
      AcariServer.TemplateManager.list_templates("zabbix"))
      |> Enum.filter(fn %{export: x} -> x end)
      |> Enum.map(fn %{id: id, name: name, description: description} ->
        %{
          id: "templ-#{id}",
          type: :script,
          title: "#{description} (#{name})",
          name: name
        }
      end)

    left_node = [
      %{
        id: "node-name",
        type: :node,
        title: "Имя",
        key: :name,
        prio: 10
      },
      %{
        id: "node-description",
        type: :node,
        title: "Описание",
        key: :description,
        prio: 20
      },
      %{
        id: "node-address",
        type: :node,
        title: "Адрес",
        key: :address,
        prio: 30
      }
    ]

    left_bogatka = [
      %{
        id: "bogatka_wizard",
        type: :bogatka,
        title: "Обнаруженные ошибки",
        key: :wizard
      }
    ]

    left = left_node ++ left_scripts ++ left_bogatka

    right = []

    type_dscr = [
      node: "Параметры клиентов",
      script: "Скрипты",
      bogatka: "ИИ Богатка"
    ]

    {:ok,
     assign(socket,
      user: user,
       type_descr: type_dscr,
       groups: groups,
       group_id: group_id,
       classes: classes,
       left: left,
       left_groups: group_left(left),
       right: right,
       table: []
     )}
  end

  @impl true
  def handle_event("select_group", %{"value" => id}, socket) do
    {:noreply, assign(socket, group_id: id, table: [])}
  end

  def handle_event("left", params, socket) do
    {left, right} = left_to_right(socket.assigns, params["id"])
    {:noreply, assign(socket, left: left, left_groups: group_left(left), right: right, table: [])}
  end

  def handle_event("right", params, socket) do
    {right, left} = right_to_left(socket.assigns, params["id"])

    {:noreply,
     assign(socket,
       left: left,
       left_groups: group_left(left),
       right: right,
       table: []
     )}
  end

  def handle_event("move_down", %{"id" => id}, socket) do
    right = move_down(socket.assigns.right, id)
    {:noreply, assign(socket, right: right, table: [])}
  end

  def handle_event("move_up", %{"id" => id}, socket) do
    right = move_up(socket.assigns.right, id)
    {:noreply, assign(socket, right: right, table: [])}
  end

  def handle_event("draw", _, socket) do
    tag_list =
      socket.assigns.right
      |> Enum.map(fn
        %{name: name} -> name
        %{title: title} -> title
      end)


    nodes =
      case socket.assigns.group_id do
        "nil" ->
          AcariServer.NodeManager.list_nodes(socket.assigns[:user])

        _ ->
          AcariServer.GroupManager.get_group!(socket.assigns.group_id)
          |> Map.get(:nodes)
      end

    value_list =
      nodes
      |> Enum.map(fn %{name: tun_name} = node ->
        tun_state =
          AcariServer.Mnesia.get_tunnel_state(tun_name)

        socket.assigns.right
        |> Enum.map(fn
          %{type: :script, name: name} ->
            tun_state[name][:data]

          %{type: :node, key: key} ->
            Map.get(node, key)

          %{type: :bogatka, key: key} ->
            (tun_state[key] || [])
            |> Enum.map(fn
              {"errormsg[" <> port, %{value: value}} ->
                "#{String.slice(port, 0..-2)}: #{value}"

              _ ->
                nil
            end)
            |> Enum.reject(&is_nil/1)
            |> Enum.join("\n")


          %{name: _} ->
            ""
        end)
      end)

    table = [tag_list | value_list]

    {:noreply, assign(socket, table: table)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp left_to_right(assigns, id) do
    from_to(assigns.left, assigns.right, id)
  end

  defp right_to_left(assigns, id) do
    from_to(assigns.right, assigns.left, id)
  end

  defp from_to(from, to, id) do
    {el, from} =
      from
      |> Enum.split_with(fn
        %{id: ^id} -> true
        _ -> false
      end)

    {from, to ++ el}
  end

  defp move_up(list, id) do
    list
    |> Enum.reverse()
    |> move_down(id)
    |> Enum.reverse()
  end

  defp move_down(list, id) do
    {pref, suff} =
      list
      |> Enum.split_while(fn
        %{id: ^id} -> false
        _ -> true
      end)

    pref ++ swap(suff)
  end

  defp swap([a, b | tail]) do
    [b, a | tail]
  end

  defp swap(l), do: l

  defp sort_left(left) do
    left
    |> Enum.sort_by(fn %{type: type, title: title} = el -> {type, el[:prio] || title} end)
  end

  defp group_left(left) do
    left
    |> sort_left()
    |> Enum.group_by(fn %{type: type} -> type end)
  end
end
