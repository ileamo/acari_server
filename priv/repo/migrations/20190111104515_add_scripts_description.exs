defmodule AcariServer.Repo.Migrations.AddScriptsDescription do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      add :description, :string
    end
  end
end
