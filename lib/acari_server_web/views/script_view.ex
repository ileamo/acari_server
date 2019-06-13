defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  defdelegate get_script_with_prefix(script, templ), to: AcariServer.Template

  def eval_prefix(script, test_ass) do
    AcariServer.Template.eval(script.prefix, test_ass)
  end

  def templates_list(script) do
    script.templates
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(", ")
  end

  def templ_id_list(nil) do
    []
  end

  def templ_id_list(script) do
    script.templates
    |> Enum.map(fn %{id: id} -> id end)
  end

end
