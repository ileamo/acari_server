defmodule AcariServer.ScriptManager.Script do
  use Ecto.Schema
  import Ecto.Changeset


  schema "scripts" do
    field :local, :string
    field :name, :string
    field :remote, :string

    timestamps()
  end

  @doc false
  def changeset(script, attrs) do
    script
    |> cast(attrs, [:name, :local, :remote])
    |> validate_required([:name, :local, :remote])
    |> unique_constraint(:name)
  end
end
