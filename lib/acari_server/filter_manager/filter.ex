defmodule AcariServer.FilterManager.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "filrers" do
    field :common, :boolean, default: false
    field :description, :string
    field :filter, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:description, :filter, :common])
    |> validate_required([:description, :filter, :common])
  end
end
