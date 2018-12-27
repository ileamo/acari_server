defmodule AcariServer.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :is_admin, :boolean, default: false
    field :password_hash, :string
    field :username, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :is_admin])
    |> validate_required([:username, :password, :is_admin])
    |> validate_length(:username, min: 3, max: 32)
    |> validate_length(:password, min: 5, max: 32)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end
