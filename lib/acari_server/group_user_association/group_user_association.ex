defmodule AcariServer.GroupUserAssociation do
  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.GroupUserAssociation.GroupUser

  def create_group_user(attrs \\ %{}) do
    %GroupUser{}
    |> GroupUser.changeset(attrs)
    |> Repo.insert()
  end
end
