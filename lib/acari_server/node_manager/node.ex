defmodule AcariServer.NodeManager.Node do
  use Ecto.Schema
  import Ecto.Changeset


  schema "nodes" do
    field :description, :string
    field :groups, {:array, :string}
    field :name, :string
    field :params, :map
    field :sn, :string
    field :templates, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:sn, :name, :description, :groups, :templates, :params])
    |> validate_required([:sn, :name, :description, :groups, :templates, :params])
    |> unique_constraint(:sn)
    |> unique_constraint(:name)
  end
end
