defmodule AcariServer.ScriptManager.Script do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scripts" do
    field :local, :string
    field :description, :string
    field :name, :string
    field :remote, :string
    field :definition, :string
    field :prefix, :string
    field :test, :string
    field :inventory, :string
    field :telemetry, :string

    has_many :nodes, AcariServer.NodeManager.Node
    has_many :templates, AcariServer.TemplateManager.Template

    timestamps()
  end

  @doc false
  def changeset(script, attrs) do
    script
    |> cast(attrs, [
      :name,
      :description,
      :local,
      :remote,
      :definition,
      :prefix,
      :test,
      :inventory,
      :telemetry
    ])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
