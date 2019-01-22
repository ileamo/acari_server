defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  defdelegate get_script_with_prefix(script, templ), to: AcariServer.Template

  def eval_script(templ, script, test_ass) do
    templ = get_script_with_prefix(script, templ)
    AcariServer.Template.eval(templ, test_ass)
  end
end
