defmodule AcariServer.ScriptTemplateAssociation.ScriptTemplate do
  use Ecto.Schema

  @primary_key false
  schema "scripts_templates" do
    belongs_to :script, AcariServer.ScriptManager.Script
    belongs_to :template, AcariServer.TemplateManager.Template

    timestamps()
  end

  def changeset(script_template, attrs \\ %{}) do
    script_template
    |> Ecto.Changeset.cast(attrs, [:script_id, :template_id])
    |> Ecto.Changeset.validate_required([:script_id, :template_id])
    |> Ecto.Changeset.foreign_key_constraint(:script_id)
    |> Ecto.Changeset.foreign_key_constraint(:template_id)
    |> Ecto.Changeset.unique_constraint(:script_id, name: :script_id_template_id_index)
  end
end
