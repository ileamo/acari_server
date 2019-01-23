defmodule AcariServerWeb.TemplateView do
  use AcariServerWeb, :view
  @no_script "<NO_SCRIPT>"

  def script_name_id_pairs_list() do
    AcariServer.ScriptManager.script_name_id_pairs_list(@no_script)
  end

  def script_name(node) do
    case node.script do
      nil -> @no_script
      scr -> scr.name
    end
  end
end
