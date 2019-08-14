defmodule AcariServerWeb.GrpOperChannel do
  use AcariServerWeb, :channel

  def join("grp_oper:" <> _id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("input", params, socket) do
    IO.inspect(params)

    case params["cmd"] do
      "get_script" ->
        push(socket, "output", %{
          id: "script",
          opt: AcariServer.NodeMonitor.get_templ_descr_by_name(params["template_name"])
        })

      "script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          AcariServer.GroupManager.get_group!(params["group_id"])
          |> Map.get(:nodes)
          |> Enum.each(fn %{name: name} ->
            AcariServer.Master.exec_script_on_peer(name, tag)
          end)
        else
          _ ->
            push(socket, "output", %{
              id: "script",
              data:
                "                            ^\n" <>
                  "Выберите скрипт из меню ----|",
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
end
