defmodule AcariServer.ServerManager.Server do
  use Ecto.Schema
  import Ecto.Changeset


  schema "servers" do
    field :description, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
