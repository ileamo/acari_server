defmodule AcariServer.Repo.Migrations.AlterNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      remove :groups
      remove :templates
    end
  end
end
