defmodule AcariServer.ScriptTemplateAssociation do
  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.ScriptTemplateAssociation.ScriptTemplate

  def create_group_node(attrs \\ %{}) do
    %ScriptTemplate{}
    |> ScriptTemplate.changeset(attrs)
    |> Repo.insert()
  end
end
