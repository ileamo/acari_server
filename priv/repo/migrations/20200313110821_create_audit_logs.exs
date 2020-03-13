defmodule AcariServer.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :username, :string
      add :object, :string
      add :object_name, :string
      add :operation, :string
      add :params, :text

      timestamps()
    end

  end
end
