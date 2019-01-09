defmodule AcariServer.Repo.Migrations.RmSnFromNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      remove :sn
    end
  end
end
