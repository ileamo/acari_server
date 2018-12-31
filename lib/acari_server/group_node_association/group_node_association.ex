defmodule AcariServer.GroupNodeAssociation do
  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.GroupNodeAssociation.GroupNode

  def create_group_node(attrs \\ %{}) do
    %GroupNode{}
    |> GroupNode.changeset(attrs)
    |> Repo.insert()
  end
end
