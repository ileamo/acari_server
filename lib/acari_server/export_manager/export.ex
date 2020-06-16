defmodule AcariServer.ExportManager.Export do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exports" do
    field :common, :boolean, default: false
    field :name, :string
    field :profile, :map
    belongs_to :user, AcariServer.UserManager.User

    timestamps()
  end

  @doc false
  def changeset(export, attrs) do
    export
    |> cast(attrs, [:name, :profile, :common, :user_id])
    |> validate_required([:name, :profile, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
