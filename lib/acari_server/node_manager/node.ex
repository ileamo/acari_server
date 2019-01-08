defmodule AcariServer.NodeManager.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :sn, :string
    field :name, :string
    field :description, :string
    field :params, :map
    field :groups_list, {:array, :integer}, virtual: true

    many_to_many :groups, AcariServer.GroupManager.Group,
      join_through: AcariServer.GroupNodeAssociation.GroupNode

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:sn, :name, :description, :params])
    |> validate_required([:sn, :name])
    |> unique_constraint(:sn)
    |> unique_constraint(:name)
  end
end