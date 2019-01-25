defmodule ScriptFunc do
  alias AcariServer.TemplateAgent

  def path_to(name) do
    case TemplateAgent.add_templ?(self(), name) do
      {assigns, prefix} ->
        TemplateAgent.add_templ(self(), name)

        templ =
          case AcariServer.TemplateManager.get_template_by_name(name) do
            %{template: templ} -> AcariServer.Template.eval(prefix <> templ, assigns) |> elem(0)
            _ -> nil
          end

        TemplateAgent.add_templ(self(), name, templ)

      _ ->
        nil
    end

    "./#{name}"
  end
end
