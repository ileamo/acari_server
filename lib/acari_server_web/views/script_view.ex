defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  defdelegate get_script_with_prefix(script, templ), to: AcariServer.Template

  def eval_prefix(script, test_ass) do
    AcariServer.Template.eval(script.prefix, test_ass)
  end
end
