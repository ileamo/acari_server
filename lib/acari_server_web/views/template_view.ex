defmodule AcariServerWeb.TemplateView do
  use AcariServerWeb, :view
  alias AcariServer.Validator

  @no_script "<NO_CLASS>"

  def script_name_id_pairs_list() do
    AcariServer.ScriptManager.script_name_id_pairs_list(@no_script)
  end

  def script_name(node) do
    case node.script do
      nil -> @no_script
      scr -> scr.name
    end
  end

  def eval_template(prefix, templ, test_ass) do
    templ = (prefix || "") <> templ
    AcariServer.Template.eval(templ, test_ass)
  end

  def validate(validator, text) do
    with val_fn when is_function(val_fn) <- Validator.validators()[validator] do
      val_fn.(text)
    else
      _ -> :ok
    end
  end
end
