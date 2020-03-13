defmodule AcariServer.AuditManager.Audit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :object, :string, default: ""
    field :object_name, :string, default: ""
    field :operation, :string, default: ""
    field :params, :map, default: %{}
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(audit, attrs) do
    audit
    |> cast(attrs, [:username, :object, :object_name, :operation, :params])
    |> validate_required([:username])
  end
end
