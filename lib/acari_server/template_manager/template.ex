defmodule AcariServer.TemplateManager.Template do
  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :description, :string
    field :name, :string
    field :template, :string
    belongs_to :script, AcariServer.ScriptManager.Script

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :description, :template, :script_id])
    |> validate_required([:name, :template])
    |> foreign_key_constraint(:script_id)
    |> unique_constraint(:name)
  end
end
