defmodule AcariServer.ScriptManager.Script do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scripts" do
    field :local, :string
    field :description, :string
    field :name, :string
    field :remote, :string
    field :definition, :string

    has_many :nodes, AcariServer.NodeManager.Node

    timestamps()
  end

  @doc false
  def changeset(script, attrs) do
    script
    |> cast(attrs, [:name, :description, :local, :remote, :definition])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
