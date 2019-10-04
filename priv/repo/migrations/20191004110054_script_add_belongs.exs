defmodule AcariServer.Repo.Migrations.ScriptAddBelongs do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      remove(:local)
      remove(:remote)
      add(:local_id, references(:templates, on_delete: :nilify_all))
      add(:remote_id, references(:templates, on_delete: :nilify_all))
    end
  end
end
