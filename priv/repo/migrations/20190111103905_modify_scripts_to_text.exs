defmodule AcariServer.Repo.Migrations.ModifyScriptsToText do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      modify :local, :text
      modify :remote, :text
    end
  end
end
