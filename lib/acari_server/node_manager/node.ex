defmodule AcariServer.NodeManager.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :name, :string
    field :description, :string, default: ""
    field :address, :string, default: ""
    field :params, :map, default: %{}
    field :latitude, :float, default: 55.777594
    field :longitude, :float, default: 37.737926
    field :lock, :boolean, default: false

    field :groups_list, {:array, :integer}, virtual: true
    belongs_to :script, AcariServer.ScriptManager.Script

    many_to_many :groups, AcariServer.GroupManager.Group,
      join_through: AcariServer.GroupNodeAssociation.GroupNode,
      on_replace: :delete

    has_many :client_comments, AcariServer.ClientCommentManager.ClientComment

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [
      :name,
      :description,
      :address,
      :params,
      :script_id,
      :latitude,
      :longitude,
      :lock
    ])
    |> validate_required([:name])
    |> foreign_key_constraint(:script_id)
    |> unique_constraint(:name)
  end
end
