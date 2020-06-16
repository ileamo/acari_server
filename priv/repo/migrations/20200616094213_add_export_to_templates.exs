defmodule AcariServer.Repo.Migrations.AddExportToTemplates do
  use Ecto.Migration

  def change do
      alter table(:templates) do
        add(:export, :boolean, default: true, null: true)
      end

  end
end
