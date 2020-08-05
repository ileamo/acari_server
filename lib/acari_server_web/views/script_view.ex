defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  defdelegate get_script_with_prefix(script, templ), to: AcariServer.Template
  defdelegate templ_name_id_pairs_list(type), to: AcariServer.TemplateManager

  def templates_list(script) do
    script.templates
    |> get_templates_list()
  end

  def terminals_list(script) do
    script.terminals
    |> get_templates_list()
  end

  defp get_templates_list(templates) do
    templates
    |> Enum.map(fn %{description: descr} -> descr end)
    |> Enum.sort()
    |> Enum.join(",\n")
  end



  def templ_id_list(nil) do
    []
  end

  def templ_id_list(script) do
    script.templates
    |> Enum.map(fn %{id: id} -> id end)
  end
  def term_id_list(nil) do
    []
  end

  def term_id_list(script) do
    script.terminals
    |> Enum.map(fn %{id: id} -> id end)
  end
end
