defmodule AcariServer.ServerManager.Server do
  use Ecto.Schema
  import Ecto.Changeset


  schema "servers" do
    field :description, :string
    field :name, :string
    field :system_name, :string

    timestamps()
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :system_name, :description])
    |> validate_required([:name, :system_name])
    |> unique_constraint(:name)
    |> unique_constraint(:system_name)
  end
end
