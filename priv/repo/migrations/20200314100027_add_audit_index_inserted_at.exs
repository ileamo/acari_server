defmodule AcariServer.Repo.Migrations.AddAuditIndexInsertedAt do
  use Ecto.Migration

  def change do
    create(index(:chat_messages, [:inserted_at]))
  end
end
