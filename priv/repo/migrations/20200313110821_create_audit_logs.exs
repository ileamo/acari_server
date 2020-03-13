defmodule AcariServer.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add(:username, :string)
      add(:object, :string)
      add(:object_name, :string)
      add(:operation, :string)
      add(:params, :map)

      timestamps()
    end

    create(index(:audit_logs, [:inserted_at]))
    create(index(:audit_logs, [:username]))
    create(index(:audit_logs, [:object]))
    create(index(:audit_logs, [:object_name]))
  end
end
