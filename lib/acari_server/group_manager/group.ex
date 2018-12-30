defmodule AcariServer.GroupManager.Group do
  use Ecto.Schema
  import Ecto.Changeset


  schema "groups" do
    field :description, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
