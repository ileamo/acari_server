defmodule AcariServer.Repo.Migrations.AddScriptsPrefix do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      add(:prefix, :text)
      add(:test, :text)
    end
  end
end
