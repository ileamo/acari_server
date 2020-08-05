defmodule AcariServer.ClassTerminalAssociation.ClassTerminal do
  use Ecto.Schema

  @primary_key false
  schema "classes_terminals" do
    belongs_to :script, AcariServer.ScriptManager.Script
    belongs_to :template, AcariServer.TemplateManager.Template

    timestamps()
  end

  def changeset(class_terminal, attrs \\ %{}) do
    class_terminal
    |> Ecto.Changeset.cast(attrs, [:script_id, :template_id])
    |> Ecto.Changeset.validate_required([:script_id, :template_id])
    |> Ecto.Changeset.foreign_key_constraint(:script_id)
    |> Ecto.Changeset.foreign_key_constraint(:template_id)
    |> Ecto.Changeset.unique_constraint(:script_id, name: :class_id_terminal_id_index)
  end
end
