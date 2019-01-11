defmodule AcariServer.ScriptManager.Script do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scripts" do
    field :local, :string
    field :description, :string
    field :name, :string
    field :remote, :string

    timestamps()
  end

  @doc false
  def changeset(script, attrs) do
    script
    |> cast(attrs, [:name, :description, :local, :remote])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
