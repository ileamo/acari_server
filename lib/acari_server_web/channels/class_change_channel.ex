defmodule AcariServerWeb.ClassChangeChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  def join("class_change:" <> _id, %{"pathname" => pathname}, socket) do
    node_id =
      case Regex.run(~r|nodes/([\d]+)|, pathname) do
        [_, id] -> String.to_integer(id)
        _ -> nil
      end

    {:ok, assign(socket, :node_id, node_id)}
  end

  def handle_in("input", %{"class_id" => ids}, socket) do
    {vars, class_id} =
      with {id, ""} when is_integer(id) <- Integer.parse(ids),
           class = %AcariServer.ScriptManager.Script{} <- AcariServer.ScriptManager.get_script(id) do
        {AcariServer.Template.get_vars(class.definition), id}
      else
        _ -> {%{}, nil}
      end

    node_params =
      with class_id when is_integer(class_id) <- class_id,
           node_id when is_integer(node_id) <- socket.assigns[:node_id],
           node = %AcariServer.NodeManager.Node{} <- AcariServer.NodeManager.get_node!(node_id),
           script_id when is_integer(script_id) <- node.script_id,
           true <- script_id == class_id do
        node.params
      else
        _ ->
          nil
      end

    node_params_form_html =
      Phoenix.View.render_to_string(AcariServerWeb.NodeView, "parameters_form.html",
        vars: vars,
        node_params: node_params
      )

    push(socket, "output", %{data: node_params_form_html})
    {:noreply, socket}
  end
end
