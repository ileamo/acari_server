defmodule TemplFunc do
  alias AcariServer.TemplateAgent
  alias AcariServer.Template

  def std_funcs() do
    %{
      "path_to" => fn x, _render ->
        path_to(x |> String.trim())
      end,
      "include_file" => fn x, _render ->
        include_file(x |> String.trim())
      end,
      "include_templ" => &include_templ/2,
      "Lua" => &lua/2
    }
  end

  def path_to(name) do
    case TemplateAgent.add_templ?(self(), name) do
      {assigns, prefix} ->
        TemplateAgent.add_templ(self(), name)

        templ =
          with %AcariServer.TemplateManager.Template{} = templ <-
                 AcariServer.TemplateManager.get_template_by_name(name),
               {:ok, script} <-
                 Template.eval(templ, prefix, assigns) do
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

  defp include_file(path) do
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

  defp lua(body, render) do
    case Sandbox.init()
         |> Sandbox.eval(render.(body)) do
      {:ok, res} when is_binary(res) -> res
      {:ok, res} -> inspect(res, pretty: true)
      {:error, err} -> "Lua eror: #{Template.humanize_lua_err(err)}"
    end
  end

  defp include_templ(body, render) do
    [_, templ_name, json] = Regex.run(~r/^\s*([^\s]+)\s+(.*)/, body)

    with %AcariServer.TemplateManager.Template{} = templ <-
           AcariServer.TemplateManager.get_template_by_name(templ_name) do
      assigns =
        case Jason.decode(json) do
          {:ok, %{} = a} -> a
          _ -> nil
        end

      template =
        if assigns do
          delimiter = case assigns["DELIMITER"] do

            nil -> "{{={% %}=}}"
            dl -> "{{=#{dl}=}}"
          end

          :bbmustache.render(
            delimiter <> templ.template,
            assigns,
            key_type: :binary,
            escape_fun: & &1
          )
        else
          templ.template
        end

      render.(template)
    else
      _ -> ""
    end
  end
end
