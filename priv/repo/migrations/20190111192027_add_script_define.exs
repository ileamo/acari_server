defmodule AcariServer.Repo.Migrations.AddScriptDefine do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      add(:definition, :text)
    end
  end
end
