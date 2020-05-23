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

  def update_changeset(node, attrs, nil) do
    changeset(node, attrs)
    |> validate_change(:name, &validate_update_node_name/2)
  end

  def update_changeset(node, attrs, user) do
    ch = update_changeset(node, attrs, nil)

    with true <- !user.is_admin,
         "ro" <- AcariServer.UserManager.get_user_node_rights(user, node.id) do
      ch
      |> validate_change(:params, &validate_update_ro/2)
      |> validate_change(:script_id, &validate_update_ro/2)
    else
      _ ->
        ch
    end
  end

  defp validate_update_node_name(:name, _), do: [name: "Имя клиента не может быть изменено"]
  defp validate_update_ro(:params, _), do: [{:params, "Нет прав на изменение параметров"}]
  defp validate_update_ro(attr_name, _), do: [{attr_name, "Нет прав на изменение параметра"}]
end
