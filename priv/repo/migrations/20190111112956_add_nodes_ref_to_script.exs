defmodule AcariServer.Repo.Migrations.AddNodesRefToScript do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add :script_id, references(:scripts, on_delete: :nilify_all)
    end
  end
end
