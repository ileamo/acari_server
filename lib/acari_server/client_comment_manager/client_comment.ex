defmodule AcariServer.ClientCommentManager.ClientComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "client_comments" do
    field :comment, :string
    belongs_to :user, AcariServer.UserManager.User
    belongs_to :node, AcariServer.NodeManager.Node

    timestamps()
  end

  @doc false
  def changeset(client_comment, attrs) do
    client_comment
    |> cast(attrs, [:comment, :user_id, :node_id])
    |> validate_required([:comment])
    |> Ecto.Changeset.foreign_key_constraint(:user_id)
    |> Ecto.Changeset.foreign_key_constraint(:node_id)
  end
end
