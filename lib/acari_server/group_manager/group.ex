defmodule AcariServer.GroupManager.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    field :description, :string

    many_to_many :nodes, AcariServer.NodeManager.Node,
      join_through: AcariServer.GroupNodeAssociation.GroupNode

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
