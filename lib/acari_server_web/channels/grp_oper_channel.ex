defmodule AcariServerWeb.GrpOperChannel do
  use AcariServerWeb, :channel

  def join("grp_oper:" <> _id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("input", params, socket) do
    IO.inspect(params, label: "PARAMS")

    case params["cmd"] do
      "select" ->
        nodes =
          case params["group_id"] do
            "nil" ->
              AcariServer.NodeManager.list_nodes()

            id ->
              AcariServer.GroupManager.get_group!(id).nodes
          end

        id_name =
          nodes
          |> get_class_list()
          |> Enum.map(fn {id, class} -> {id, class.name} end)

        nodes =
          nodes
          |> node_filter(params["filter"], socket)

        %{common_script: cs, class_list: cl} = get_group_scripts(nodes)

        script_list =
          case params["class_id"] do
            "nil" ->
              cs

            class_id ->
              cl
              |> Enum.find(fn
                {{id, _}, _} -> id == String.to_integer(class_id)
                _ -> false
              end)
              |> case(
                do:
                  (
                    {_, l} -> l
                    _ -> cs
                  )
              )
          end

        push(socket, "output", %{
          id: "select",
          class_id:
            if params["class_id"] == "nil" or
                 Enum.find(id_name, fn {id, _} ->
                   id == params["class_id"] |> String.to_integer()
                 end) do
              params["class_id"]
            else
              "nil"
            end,
          class_list:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "class_list.html",
              class_list: id_name
            ),
          script_list:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "script_list.html",
              script_list: script_list
            )
        })

      "get_script" ->
        case params["template_name"] do
          nil ->
            push(socket, "output", %{
              id: "script",
              opt: "Скрипт не определен",
              data: ""
            })

          tag ->
            get_script(socket, tag, params["group_id"], params["class_id"], params["filter"])
        end

      "script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          AcariServer.Mnesia.add_grp_oper(params["group_id"], tag)

          get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])
          |> Enum.each(fn %{name: name} ->
            AcariServer.Master.exec_script_on_peer(name, tag)
          end)

          Process.sleep(1_000)
          get_script(socket, tag, params["group_id"], params["class_id"], params["filter"])
        else
          _ ->
            push(socket, "output", %{
              id: "script",
              data:
                "<pre><code>                            ^\n" <>
                  "Выберите скрипт из меню ----|</code></pre>",
              opt: "Скрипт не определен"
            })
        end

      "repeat_script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          req_ts = AcariServer.Mnesia.get_grp_oper_timestamp(params["group_id"], tag)

          get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])
          |> Enum.filter(fn %{name: name} ->
            with stat = %{} <- AcariServer.Mnesia.get_tunnel_state(name),
                 %{timestamp: ts} <- stat[tag] do
              ts < req_ts
            else
              _ ->
                true
            end
          end)
          |> Enum.each(fn %{name: name} ->
            AcariServer.Master.exec_script_on_peer(name, tag)
          end)

          Process.sleep(1_000)
          get_script(socket, tag, params["group_id"], params["class_id"], params["filter"])
        end

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_info({:output, id, data, opt}, socket) do
    push(socket, "output", %{id: id, data: data, opt: opt})
    {:noreply, socket}
  end

  defp get_nodes_list(socket, group_id, class_id, filter) do
    class_id =
      case class_id do
        "nil" -> nil
        nil -> nil
        id_str -> String.to_integer(id_str)
      end

    nodes =
      case group_id do
        "nil" ->
          AcariServer.NodeManager.list_nodes()

        group_id ->
          AcariServer.GroupManager.get_group!(group_id)
          |> Map.get(:nodes)
      end

    case class_id do
      nil ->
        nodes

      class_id ->
        nodes |> Enum.filter(fn %{script_id: id} -> id == class_id end)
    end
    |> node_filter(filter, socket)
  end

  defp get_script(socket, tag, group_id, class_id, filter) do
    script_res_list =
      get_nodes_list(socket, group_id, class_id, filter)
      |> Enum.map(fn %{name: name} -> name end)
      |> Enum.map(fn tun_name ->
        %{timestamp: ts, data: data} =
          AcariServer.Mnesia.get_tunnel_state(tun_name)[tag] ||
            %{timestamp: 0, data: "нет данных"}

        %{id: tun_name, timestamp: ts, data: data |> to_string()}
      end)

    push(socket, "output", %{
      id: "script",
      opt: AcariServer.NodeMonitor.get_templ_descr_by_name(tag) <> " (#{tag})",
      data:
        Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "oper_res.html",
          script_res_list: script_res_list,
          request_date: AcariServer.Mnesia.get_grp_oper_timestamp(group_id, tag)
        )
    })
  end

  defp get_class_list(nodes) do
    nodes
    |> Enum.reduce([], fn
      %{script_id: nil}, acc ->
        acc

      node, acc ->
        case Enum.find(acc, fn {id, _} -> id == node.script_id end) do
          nil -> [{node.script_id, AcariServer.ScriptManager.get_script!(node.script_id)} | acc]
          _ -> acc
        end
    end)
  end

  defp get_group_scripts(nodes) do
    class_id_list = get_class_list(nodes)

    class_list =
      class_id_list
      |> Enum.map(fn
        nil ->
          {nil, MapSet.new()}

        {_, class} ->
          {{class.id, class.name},
           class.templates
           |> Enum.map(fn %{description: descr, name: name} -> {descr, name} end)
           |> MapSet.new()}
      end)

    common_script =
      class_list
      |> Enum.reduce(nil, fn
        {_, ms}, nil -> ms
        {_, ms}, acc -> MapSet.intersection(acc, ms)
      end)
      |> case(
        do:
          (
            nil -> []
            ms -> MapSet.to_list(ms)
          )
      )

    %{class_list: class_list, common_script: common_script}
  end

  def node_filter(node_list, filter_str, socket) do
    filter_str = if to_string(filter_str) |> String.trim() == "", do: "true", else: filter_str

    #    try do
    push_filter_error(socket, "")

    node_list
    |> Enum.filter(fn node ->
      state =
        (AcariServer.Mnesia.get_tunnel_state(node.name) || [])
        |> Enum.map(fn
          {tag, %{data: data}} -> {tag, try_to_number(data)}
          x -> x
        end)
        |> Enum.into(%{})

      try do
        Code.eval_string(filter_str, client: node, state: state)
        |> elem(0)
      rescue
        e in CompileError ->
          push_filter_error(socket, e.description)
          true

        value ->
          push_filter_error(socket, inspect(value))
          true
      end
    end)

    # rescue
    #   e in CompileError ->
    #     push_filter_error(socket, e.description)
    #     node_list
    #
    #   value ->
    #     push_filter_error(socket, inspect(value))
    #     node_list
    # end
  end

  defp push_filter_error(socket, data) do
    push(socket, "output", %{
      id: "filter_error",
      data: data
    })
  end

  defp try_to_number(data) do
    str =
      data
      |> to_string()
      |> String.trim()

    case Integer.parse(str) do
      {n, ""} ->
        n

      _ ->
        case Float.parse(str) do
          {n, ""} -> n
          _ -> str
        end
    end
  end
end
