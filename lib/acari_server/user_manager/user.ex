defmodule AcariServer.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :is_admin, :boolean, default: false
    field :password_hash, :string
    field :username, :string
    field :description, :string
    field :password, :string, virtual: true
    field :rpt_psw, :string, virtual: true
    field :groups_list, {:array, :integer}, virtual: true

    has_many :notes, AcariServer.NoteManager.Note

    many_to_many :groups, AcariServer.GroupManager.Group,
      join_through: AcariServer.GroupUserAssociation.GroupUser,
      on_replace: :delete

    has_many :groups_users, AcariServer.GroupUserAssociation.GroupUser
    has_many :filters, AcariServer.FilterManager.Filter
    has_many :exports, AcariServer.ExportManager.Export
    has_many :client_comments, AcariServer.ClientCommentManager.ClientComment
    has_many :chat_messages, AcariServer.ChatManager.Chat

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :description, :password, :rpt_psw, :is_admin])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 32)
    |> validate_length(:password, min: 5, max: 32)
    |> unique_constraint(:username)
    |> validate_rpt_psw()
    |> put_password_hash()
  end

  defp validate_rpt_psw(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    rpt_psw = get_field(changeset, :rpt_psw)

    case password == rpt_psw do
      true -> changeset
      _ -> add_error(changeset, :rpt_psw, "Пароли не совпадают")
    end
  end

  defp validate_rpt_psw(changeset), do: changeset

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
