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
            "nil" -> AcariServer.NodeManager.list_nodes()
            id -> AcariServer.GroupManager.get_group!(id).nodes
          end

        %{common_script: cs, class_list: cl} =
          get_group_scripts(nodes)
          |> IO.inspect()

        script_list =
          case params["class_id"] do
            "nil" ->
              cs

            class_id ->
              cl
              |> IO.inspect()
              |> Enum.find(fn
                {{id, _}, _} -> id == String.to_integer(class_id)
                _ -> false
              end)
              |> case(
                do:
                  (
                    {_, l} -> l
                    _ -> []
                  )
              )
          end

        push(socket, "output", %{
          id: "script_list",
          data:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "script_list.html",
              script_list: script_list
            ),
          opt: ""
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
            get_script(socket, tag, params["group_id"], params["class_id"])
        end

      "script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          AcariServer.Mnesia.add_grp_oper(params["group_id"], tag)

          get_nodes_list(params["group_id"], params["class_id"])
          |> Enum.each(fn %{name: name} ->
            AcariServer.Master.exec_script_on_peer(name, tag)
          end)

          Process.sleep(1_000)
          get_script(socket, tag, params["group_id"], params["class_id"])
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

          get_nodes_list(params["group_id"], params["class_id"])
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
          get_script(socket, tag, params["group_id"], params["class_id"])
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

  defp get_nodes_list(group_id, class_id, _filter \\ "") do
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
  end

  defp get_script(socket, tag, group_id, class_id, filter \\ "") do
    IO.inspect({tag, group_id, class_id, filter}, label: "GET_SCRIPT")

    script_res_list =
      get_nodes_list(group_id, class_id, filter)
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
        Phoenix.View.render_to_string(AcariServerWeb.GroupView, "oper_res.html",
          script_res_list: script_res_list,
          request_date: AcariServer.Mnesia.get_grp_oper_timestamp(group_id, tag)
        )
    })
  end

  defp get_group_scripts(nodes) do
    class_id_list =
      nodes
      |> Enum.reduce([], fn node, acc ->
        case Enum.member?(acc, node.script_id) do
          false -> [node.script_id | acc]
          _ -> acc
        end
      end)

    class_list =
      class_id_list
      |> Enum.map(fn
        nil ->
          {nil, MapSet.new()}

        id ->
          class = AcariServer.ScriptManager.get_script!(id)

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
end
