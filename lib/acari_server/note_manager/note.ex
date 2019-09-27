defmodule AcariServer.NoteManager.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :body, :string
    field :subject, :string

    belongs_to :user, AcariServer.UserManager.User

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:subject, :body, :user_id])
    |> validate_required([:subject, :body])
    |> foreign_key_constraint(:user_id)
  end
end
