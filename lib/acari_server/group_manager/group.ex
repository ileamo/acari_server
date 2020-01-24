defmodule AcariServer.GroupManager.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    field :description, :string

    many_to_many :nodes, AcariServer.NodeManager.Node,
      join_through: AcariServer.GroupNodeAssociation.GroupNode

    many_to_many :users, AcariServer.UserManager.User,
      join_through: AcariServer.GroupUserAssociation.GroupUser

    has_many :schedules, AcariServer.ScheduleManager.Schedule

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end

  def put_groups(obj, %{"groups_list" => false}) do
    obj
  end

  def put_groups(obj, attrs) do
    obj
    |> put_assoc(:groups, parse_groups(attrs))
  end

  defp parse_groups(%{"groups_list" => groups_list}) do
    groups_list
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(&AcariServer.GroupManager.get_group_wo_nodes!/1)
  end

  defp parse_groups(_) do
    []
  end
end
