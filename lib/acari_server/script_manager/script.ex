defmodule AcariServer.ScriptManager.Script do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scripts" do
    #field :local, :string
    field :description, :string
    field :name, :string
    #field :remote, :string
    field :definition, :string
    field :prefix, :string
    field :test, :string
    field :templates_list, {:array, :integer}, virtual: true
    field :test_client_name, :string

    belongs_to :local, AcariServer.TemplateManager.Template
    belongs_to :remote, AcariServer.TemplateManager.Template

    has_many :nodes, AcariServer.NodeManager.Node

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
      :local_id,
      :remote_id,
      :definition,
      :prefix,
      :test,
      :test_client_name
    ])
    |> foreign_key_constraint(:local_id)
    |> foreign_key_constraint(:remote_id)
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
