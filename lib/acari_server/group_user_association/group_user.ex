defmodule AcariServer.GroupUserAssociation.GroupUser do
  use Ecto.Schema

  @primary_key false
  schema "groups_users" do
    belongs_to :group, AcariServer.GroupManager.Group
    belongs_to :user, AcariServer.UserManager.User

    timestamps()
  end

  def changeset(group_user, attrs \\ %{}) do
    group_user
    |> Ecto.Changeset.cast(attrs, [:group_id, :user_id])
    |> Ecto.Changeset.validate_required([:group_id, :user_id])
    |> Ecto.Changeset.foreign_key_constraint(:group_id)
    |> Ecto.Changeset.foreign_key_constraint(:user_id)
    |> Ecto.Changeset.unique_constraint(:group_id, name: :group_id_user_id_index)
  end
end
