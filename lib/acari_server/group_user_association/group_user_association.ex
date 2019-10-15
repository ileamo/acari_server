defmodule AcariServer.GroupUserAssociation do
  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.GroupUserAssociation.GroupUser

  def list_groups_users do
    GroupUser
    |> Repo.all()
  end


  def create_group_user(attrs \\ %{}) do
    %GroupUser{}
    |> GroupUser.changeset(attrs)
    |> Repo.insert()
  end

  def delete_user(user_id) do
    from(gu in GroupUser, where: gu.user_id == ^user_id)
    |> Repo.delete_all()
  end
end
