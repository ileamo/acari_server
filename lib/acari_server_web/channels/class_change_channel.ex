defmodule AcariServerWeb.ClassChangeChannel do
  use AcariServerWeb, :channel

  def join("class_change:" <> _id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("input", %{"class_id" => ids}, socket) do
    vars =
      with {id, ""} when is_integer(id) <- Integer.parse(ids),
           class = %AcariServer.ScriptManager.Script{} <- AcariServer.ScriptManager.get_script(id) do
        AcariServer.Template.get_vars(class.definition)
      else
        _ -> %{}
      end

    node_params_form_html =
      Phoenix.View.render_to_string(AcariServerWeb.NodeView, "parameters_form.html",
        vars: vars,
        node_params: nil
      )

    push(socket, "output", %{data: node_params_form_html})
    {:noreply, socket}
  end
end
