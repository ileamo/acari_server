defmodule AcariServerWeb.ExportLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(_params, %{"current_user_id" => user_id} = _session, socket) do
    user = AcariServer.UserManager.get_user!(user_id, :clean)

    groups =
      AcariServer.GroupManager.list_groups(user)
      |> Enum.map(fn %{id: id, name: name} -> {id, name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    [{group_id, _} | _] = groups

    classes =
      AcariServer.ScriptManager.list_scripts()
      |> Enum.map(fn %{id: id, name: name} -> {id, name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    scripts =
      AcariServer.TemplateManager.list_templates("client")
      |> Enum.map(fn %{id: id, name: name, description: description} ->
        %{
          id: to_string(id),
          title: "#{description} (#{name})",
          name: name,
          type: "script"
        }
      end)

    left =
      scripts
      |> Enum.sort_by(fn %{title: title} -> title end)

    right = []

    {:ok,
     assign(socket,
       groups: groups,
       group_id: group_id,
       classes: classes,
       scripts: scripts,
       left: left,
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
    {:noreply, assign(socket, left: left, right: right, table: [])}
  end

  def handle_event("right", params, socket) do
    {right, left} = right_to_left(socket.assigns, params["id"])

    {:noreply,
     assign(socket,
       left: left |> Enum.sort_by(fn %{title: title} -> title end),
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
      |> Enum.map(fn %{name: name} -> name end)

    value_list =
      AcariServer.GroupManager.get_group!(socket.assigns.group_id)
      |> Map.get(:nodes)
      |> Enum.map(fn %{name: tun_name} = _node ->
        tun_state = AcariServer.Mnesia.get_tunnel_state(tun_name)

        [
          tun_name
          | socket.assigns.right
            |> Enum.map(fn
              %{type: "script", name: name} -> tun_state[name][:data]
              %{name: _} -> ""
            end)
        ]
      end)
      |> IO.inspect()

    table = [["Имя" | tag_list] | value_list]

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
end
