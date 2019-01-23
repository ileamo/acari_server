defmodule AcariServer.Repo.Migrations.ModifyTemplatesScriptId do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      remove(:script_id)
      add(:script_id, references(:scripts, on_delete: :nilify_all))
    end
  end
end
