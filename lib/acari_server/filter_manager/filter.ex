defmodule AcariServer.FilterManager.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "filrers" do
    field :common, :boolean, default: false
    field :description, :string
    field :filter, :string
    belongs_to :user, AcariServer.UserManager.User

    timestamps()
  end

  @doc false
  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:description, :filter, :common, :user_id])
    |> validate_required([:filter])
    |> foreign_key_constraint(:user_id)
  end
end
