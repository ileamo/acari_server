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
    field :templates_list, {:array, :integer}, virtual: true

    has_many :nodes, AcariServer.NodeManager.Node
    #has_many :templates, AcariServer.TemplateManager.Template

    many_to_many :templates, AcariServer.TemplateManager.Template,
      join_through: AcariServer.ScriptTemplateAssociation.ScriptTemplate,
      on_replace: :delete

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
      :test
    ])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def put_templates(script, attrs) do
    script
    |> put_assoc(:templates, parse_templates(attrs))
  end

  defp parse_templates(%{"templates_list" => templates_list}) do
    templates_list
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(&AcariServer.TemplateManager.get_template!/1)
  end

  defp parse_templates(_) do
    []
  end

end
