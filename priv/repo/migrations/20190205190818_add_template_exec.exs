defmodule AcariServer.Repo.Migrations.AddTemplateExec do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:executable, :boolean, default: false, null: false)
    end
  end
end
