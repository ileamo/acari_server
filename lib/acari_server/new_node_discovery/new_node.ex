defmodule AcariServer.NewNodeDiscovery.NewNode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "newnodes" do
    field :ip_addr, :string
    field :name, :string
    field :params, :map
    field :source, :string

    timestamps()
  end

  @doc false
  def changeset(new_node, attrs) do
    new_node
    |> cast(attrs, [:name, :ip_addr, :source, :params])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
