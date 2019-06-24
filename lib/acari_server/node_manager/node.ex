defmodule AcariServer.NodeManager.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :name, :string
    field :description, :string
    field :params, :map
    field :latitude, :float, default: 55.777594
    field :longitude, :float, default: 37.737926
    field :groups_list, {:array, :integer}, virtual: true
    belongs_to :script, AcariServer.ScriptManager.Script

    many_to_many :groups, AcariServer.GroupManager.Group,
      join_through: AcariServer.GroupNodeAssociation.GroupNode,
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:name, :description, :params, :script_id, :latitude, :longitude])
    |> validate_required([:name])
    |> foreign_key_constraint(:script_id)
    |> unique_constraint(:name)
  end

end
