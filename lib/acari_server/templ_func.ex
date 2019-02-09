defmodule TemplFunc do
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

  def read_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> "Error reading file #{path}: #{inspect(reason)}"
    end
  end

  def home_dir(), do: System.user_home()
end
