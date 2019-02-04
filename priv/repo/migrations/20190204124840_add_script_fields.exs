defmodule AcariServer.Repo.Migrations.AddScriptFields do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      modify :local, :string
      modify :remote, :string
      add :inventory, :string
      add :telemetry, :string
    end

  end
end
