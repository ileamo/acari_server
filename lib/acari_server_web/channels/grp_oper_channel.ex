defmodule AcariServerWeb.GrpOperChannel do
  use AcariServerWeb, :channel

  def join("grp_oper:" <> _id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("input", params, socket) do
    IO.inspect(params)

    case params["cmd"] do
      "get_script" ->
        case params["template_name"] do
          nil ->
            push(socket, "output", %{
              id: "script",
              opt: "Скрипт не определен",
              data: ""
            })

          tag ->
            get_script(socket, tag, params["group_id"])
        end

      "script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          AcariServer.Mnesia.add_grp_oper(params["group_id"], tag)

          AcariServer.GroupManager.get_group!(params["group_id"])
          |> Map.get(:nodes)
          |> Enum.each(fn %{name: name} ->
            AcariServer.Master.exec_script_on_peer(name, tag)
          end)

          Process.sleep(0)
          get_script(socket, tag, params["group_id"])
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

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_info({:output, id, data, opt}, socket) do
    push(socket, "output", %{id: id, data: data, opt: opt})
    {:noreply, socket}
  end

  def get_script(socket, tag, group_id) do
    script_res_list =
      AcariServer.GroupManager.get_group!(group_id)
      |> Map.get(:nodes)
      |> Enum.map(fn %{name: name} -> name end)
      |> Enum.map(fn tun_name ->
        %{timestamp: ts, data: data} =
          AcariServer.Mnesia.get_tunnel_state(tun_name)[tag] ||
            %{timestamp: 0, data: "нет данных"}

        %{id: tun_name, timestamp: ts, data: data |> to_string() |> String.slice(0, 16)}
      end)
      |> IO.inspect()

    push(socket, "output", %{
      id: "script",
      opt: AcariServer.NodeMonitor.get_templ_descr_by_name(tag),
      data:
        Phoenix.View.render_to_string(AcariServerWeb.GroupView, "oper_res.html",
          script_res_list: script_res_list,
          request_date: AcariServer.Mnesia.get_grp_oper_timestamp(group_id, tag)
        )
    })
  end
end
