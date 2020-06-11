defmodule AcariServerWeb.ExportLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(_params, %{"current_user_id" => user_id} = _session, socket) do
    user = AcariServer.UserManager.get_user!(user_id, :clean)

    groups =
      AcariServer.GroupManager.list_groups(user)
      |> Enum.map(fn %{id: id, name: name} -> {id, name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

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
      |> IO.inspect()

    left =
      scripts
      |> Enum.sort_by(fn %{title: title} -> title end)

    right = []

    IO.puts("MOUNTED!")

    {:ok,
     assign(socket,
       groups: groups,
       classes: classes,
       scripts: scripts,
       left: left,
       right: right,
       table: []
     )}
  end

  @impl true
  def handle_event("left", params, socket) do
    IO.inspect(event: "left", params: params)
    {left, right} = left_to_right(socket.assigns, params["id"])
    {:noreply, assign(socket, left: left, right: right, table: [])}
  end

  def handle_event("right", params, socket) do
    IO.inspect(event: "right", assigns: socket.assigns)
    {right, left} = right_to_left(socket.assigns, params["id"])

    {:noreply,
     assign(socket, left: left |> Enum.sort_by(fn %{title: title} -> title end), right: right, table: [])}
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
    IO.puts "DRAW"
    n = socket.assigns.right |> length()

    table = [
      socket.assigns.right |> Enum.map(fn %{name: name} -> name end),
      List.duplicate("title", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("1", n),
      List.duplicate("2", n)
    ]

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

    (pref ++ swap(suff))
    |> IO.inspect()
  end

  defp swap([a, b | tail]) do
    [b, a | tail]
  end

  defp swap(l), do: l
end
