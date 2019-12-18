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
    with {:ok, calculated} <- AcariServer.Template.eval_prefix(prefix, test_ass) do
      AcariServer.Template.eval(templ, test_ass |> Map.merge(calculated))
      |> IO.inspect()
    else
      {:error, mes} ->
        {:error, mes}

      res ->
        IO.inspect(res, label: "evel err")
        {:error, "ERROR"}
    end
  end

  def validate(validator, text) do
    with val_fn when is_function(val_fn) <- Validator.validators()[validator] do
      val_fn.(text)
    else
      _ -> :ok
    end
  end

  def rights_descr(rights) do
    case rights do
      "ro" -> "Ограниченные"
      "admin" -> "Администратор"
      _ -> "Полные"
    end
  end

  defdelegate highlight_line(s, n), to: AcariServer.Template
  defdelegate get_line(n), to: AcariServer.Template
end
