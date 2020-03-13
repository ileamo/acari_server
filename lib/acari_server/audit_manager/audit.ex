defmodule AcariServer.AuditManager.Audit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :object, :string
    field :object_name, :string
    field :operation, :string
    field :params, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(audit, attrs) do
    audit
    |> cast(attrs, [:username, :object, :object_name, :operation, :params])
    |> validate_required([:username, :object, :object_name, :operation, :params])
  end
end
