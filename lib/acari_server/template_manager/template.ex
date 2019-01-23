defmodule AcariServer.TemplateManager.Template do
  use Ecto.Schema
  import Ecto.Changeset


  schema "templates" do
    field :description, :string
    field :name, :string
    field :template, :string
    field :script_id, :id

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :description, :template])
    |> validate_required([:name, :description, :template])
    |> unique_constraint(:name)
  end
end
