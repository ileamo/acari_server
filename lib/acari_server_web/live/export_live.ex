defmodule AcariServerWeb.ExportLive do
  use AcariServerWeb, :live_view

  alias AcariServer.ExportManager
  alias AcariServer.ExportManager.Export

  @impl true
  def mount(_params, %{"current_user_id" => user_id} = _session, socket) do
    user =
      AcariServer.UserManager.get_user!(user_id, :clean)
      |> AcariServer.RepoRO.preload(:exports)

    current_profile =
      user.exports
      |> Enum.find(fn %{name: name} -> name == "current" end) || %{}

    groups =
      AcariServer.GroupManager.list_groups(user)
      |> Enum.map(fn %{id: id, name: name} -> {to_string(id), name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    group_id = get_selectable(Map.get(current_profile, :profile)["group_id"], groups)

    classes =
      AcariServer.ScriptManager.list_scripts()
      |> Enum.map(fn %{id: id, name: name} -> {to_string(id), name} end)
      |> Enum.sort_by(fn {_, name} -> name end)

    class_id = get_selectable(Map.get(current_profile, :profile)["class_id"], classes)

    left_scripts =
      (AcariServer.TemplateManager.list_templates("client") ++
         AcariServer.TemplateManager.list_templates("zabbix"))
      |> Enum.filter(fn %{export: x} -> x end)
      |> Enum.map(fn %{id: id, name: name, description: description} ->
        %{
          id: "templ-#{id}",
          type: :script,
          title: "#{description || name}",
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
      },
      %{
        id: "node-groups",
        type: :node,
        title: "Группы",
        key: :groups,
        prio: 40
      },
      %{
        id: "node-params",
        type: :node,
        title: "Параметры",
        key: :params,
        prio: 50
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

    {left, right} =
      Enum.reduce(
        Map.get(current_profile, :profile)["right"] || [],
        {left, right},
        fn %{"id" => id} = el, {left, right} ->
          from_to(left, right, id, %{
            filter: el["filter"],
            negative: el["negative"],
            oper: el["oper"]
          })
        end
      )

    andor = Map.get(current_profile, :profile)["andor"] || "and"

    type_dscr = [
      node: "Параметры клиентов",
      script: "Скрипты",
      bogatka: "ИИ Богатка"
    ]

    {:ok,
     assign(socket,
       user: user,
       current_profile: current_profile,
       type_descr: type_dscr,
       groups: groups,
       group_id: group_id,
       class_id: class_id,
       classes: classes,
       left: left,
       left_groups: group_left(left),
       right: right,
       andor: andor,
       table: []
     )}
  end

  @impl true
  def handle_event("select_group_class", %{"group" => group_id, "class" => class_id}, socket) do
    {:noreply, assign(socket, group_id: group_id, class_id: class_id, table: [])}
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

  def handle_event("filters", %{"_target" => ["andor"], "andor" => val}, socket) do
    {:noreply, assign(socket, andor: val, table: [])}
  end

  def handle_event("filters", %{"_target" => [field, item]} = params, socket) do
    right =
      socket.assigns.right
      |> Enum.map(fn
        %{id: ^item} = el -> Map.put(el, String.to_existing_atom(field), params[field][item])
        el -> el
      end)

    {:noreply, assign(socket, right: right, table: [])}
  end

  def handle_event("draw", _params, socket) do
    ass = socket.assigns

    tag_list =
      ass.right
      |> Enum.map(fn
        # %{name: name} -> name
        %{title: title} -> title
      end)

    nodes =
      case ass.group_id do
        "nil" ->
          AcariServer.NodeManager.list_nodes(ass[:user])

        _ ->
          AcariServer.GroupManager.get_group!(ass.group_id)
          |> Map.get(:nodes)
      end

    nodes =
      case ass.class_id do
        "nil" ->
          nodes

        class_id ->
          nodes
          |> Enum.filter(fn %{script_id: id} -> to_string(id) == class_id end)
      end
      |> AcariServer.RepoRO.preload(:groups)

    value_list =
      nodes
      |> Enum.map(fn %{name: tun_name} = node ->
        tun_state = AcariServer.Mnesia.get_tunnel_state(tun_name)

        socket.assigns.right
        |> Enum.map(fn
          %{type: :script, name: name} ->
            tun_state[name][:data]

          %{type: :node, key: key} ->
            case key do
              :groups ->
                node.groups |> Enum.map(fn %{name: name} -> name end) |> Enum.join(", ")

              _ ->
                case Map.get(node, key) do
                  value
                  when is_binary(value) or is_boolean(value) or is_nil(value) or is_number(value) ->
                    value

                  value ->
                    case Jason.encode(value, pretty: true) do
                      {:ok, res} -> res
                      _ -> inspect(value)
                    end
                end
            end

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
      |> Enum.filter(fn x ->
        Enum.zip(ass.right, x)
        |> Enum.reduce_while(true, fn
          {%{oper: "match"} = el, val}, _ ->
            match(val, el[:filter]) |> neg(el[:negative]) |> cont_halt(ass.andor)

          {%{oper: oper} = el, val}, _ when oper in ["==", "<", "<=", ">", ">="] ->
            num_cmp(oper, val, el[:filter]) |> neg(el[:negative]) |> cont_halt(ass.andor)

          {el, _}, _ ->
            neg(true, el[:negative]) |> cont_halt(ass.andor)
        end)
      end)

    table = [tag_list | value_list]

    save_current_profile(socket)

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

  defp from_to(from, to, id, extra \\ %{}) do
    {el, from} =
      from
      |> Enum.split_with(fn
        %{id: ^id} -> true
        _ -> false
      end)

    el =
      case el do
        [el] -> [Map.merge(el, extra)]
        el -> el
      end

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

  defp save_current_profile(socket) do
    ass = socket.assigns

    profile = %{
      class_id: ass.class_id,
      group_id: ass.group_id,
      andor: ass.andor,
      right: ass.right
    }

    attrs = %{user_id: ass.user.id, name: "current", profile: profile}

    case ass.current_profile do
      %Export{} = export -> ExportManager.update_export(export, attrs)
      _ -> ExportManager.create_export(attrs)
    end
  end

  defp get_selectable("nil", _) do
    "nil"
  end

  defp get_selectable(id, select_list) do
    if select_pair =
         Enum.find(select_list, fn {select_id, _} ->
           select_id == id
         end) do
      {select_id, _} = select_pair
      select_id
    else
      [{select_id, _} | _] = select_list
      select_id
    end
  end

  defp match(val, pattern) do
    Wild.match?(normalize(val), normalize(pattern))
  end

  defp num_cmp(oper, val, pattern) do
    with pattern when not is_nil(pattern) <- to_number(pattern),
         val when not is_nil(val) <- to_number(val) do
      case oper do
        "==" -> val == pattern
        ">" -> val > pattern
        ">=" -> val >= pattern
        "<" -> val < pattern
        "<=" -> val <= pattern
        _ -> false
      end
    else
      _ -> false
    end
  end

  defp to_number(str) when is_binary(str) do
    str = String.trim(str)

    case Integer.parse(str) do
      {n, ""} ->
        n

      _ ->
        case Float.parse(str) do
          {n, ""} -> n
          _ -> nil
        end
    end
  end

  defp to_number(_), do: nil

  defp normalize(str) when is_binary(str), do: String.trim(str)
  defp normalize(_), do: ""

  defp neg(val, "not"), do: !val
  defp neg(val, _), do: val

  defp cont_halt(v, "or") do
    case v do
      true -> {:halt, true}
      _ -> {:cont, false}
    end
  end

  defp cont_halt(v, _) do
    case v do
      true -> {:cont, true}
      _ -> {:halt, false}
    end
  end
end
