defmodule TemplFunc do
  alias AcariServer.TemplateAgent

  def path_to(name) do
    case TemplateAgent.add_templ?(self(), name) do
      {assigns, prefix} ->
        TemplateAgent.add_templ(self(), name)

        templ =
          with %{template: templ} <-
                 AcariServer.TemplateManager.get_template_by_name(name),
               {:ok, calculated} <- AcariServer.Template.eval_prefix(prefix, assigns),
               {:ok, script} <-
                 AcariServer.Template.eval(templ, assigns |> Map.merge(calculated)) do
            script
          else
            _ -> nil
          end

        TemplateAgent.add_templ(self(), name, templ)

      _ ->
        nil
    end

    "./#{name}"
  end

  def include_file(path) do
    path =
      case path do
        "~/" <> tail -> "#{System.user_home()}/#{tail}"
        path -> path
      end

    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> "Error reading file #{path}: #{inspect(reason)}"
    end
  end

  def home_dir(), do: System.user_home()
end
