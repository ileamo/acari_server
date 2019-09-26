defmodule AcariServer.NotesManager.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :body, :string
    field :subject, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:subject, :body])
    |> validate_required([:subject, :body])
  end
end
