defmodule AcariServer.SFX do
  alias AcariServer.TemplateAgent

  def create_sfx(templ_id, node, req_params) do
    res =
      with %{params: config_params, script: %{} = script} <- node,
           templ when is_binary(templ) <-
             AcariServer.Template.get_script_with_prefix(script, templ_id),
           prefix <- script.prefix || "",
           assigns <-
             req_params
             |> Map.merge(config_params)
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end),
           :ok <- TemplateAgent.init_templ_map(self(), assigns, prefix),
           {script, nil} <- AcariServer.Template.eval(templ, assigns) do
        templ_map = TemplateAgent.get_templ_map(self())
        IO.inspect(templ_map)
        {:ok, script}
      else
        %AcariServer.NodeManager.Node{script: nil} -> {:error, "<NO_SCRIPT>"}
        res -> res
      end

    # TemplateAgent.remove_templ_map(self())
    TemplateAgent.gc()
    res
  end
end
