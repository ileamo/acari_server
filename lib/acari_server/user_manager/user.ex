defmodule AcariServer.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :is_admin, :boolean, default: false
    field :password_hash, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password_hash, :is_admin])
    |> validate_required([:username, :password_hash, :is_admin])
    |> unique_constraint(:username)
  end
end
