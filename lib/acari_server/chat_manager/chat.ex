defmodule AcariServer.ChatManager.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :message, :string
    belongs_to :user, AcariServer.UserManager.User

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:message, :user_id])
    |> validate_required([:message])
    |> Ecto.Changeset.foreign_key_constraint(:user_id)
  end
end
