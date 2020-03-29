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

  def diff_count_to_str(diff_count) do
    diff_count
    |> Enum.reduce("Строк ", fn
      {:ins, n}, acc -> acc <> "добавлено: #{n}, "
      {:del, n}, acc -> acc <> "удалено: #{n}, "
      _, acc -> acc
    end)
  end

  def diff_to_html(template, diff) do
    Phoenix.View.render_to_string(AcariServerWeb.TemplateView, "diff_modal.html",
      template: template,
      diff: diff
    )
  end

  defdelegate highlight_line(s, n), to: AcariServer.Template
  defdelegate get_line(n), to: AcariServer.Template
  defdelegate is_executable?(type), to: AcariServer.TemplateManager
  defdelegate exec_type_csv(), to: AcariServer.TemplateManager
end
