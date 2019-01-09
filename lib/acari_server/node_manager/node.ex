defmodule AcariServer.NodeManager.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :name, :string
    field :description, :string
    field :params, :map
    field :groups_list, {:array, :integer}, virtual: true

    many_to_many :groups, AcariServer.GroupManager.Group,
      join_through: AcariServer.GroupNodeAssociation.GroupNode,
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:name, :description, :params])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def put_groups(node, attrs) do
    node
    |> put_assoc(:groups, parse_groups(attrs))
  end

  defp parse_groups(%{"groups_list" => groups_list}) do
    groups_list
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(&AcariServer.GroupManager.get_group_wo_nodes!/1)
  end
end
