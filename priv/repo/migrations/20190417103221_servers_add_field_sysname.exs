defmodule AcariServer.Repo.Migrations.ServersAddFieldSysname do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add(:system_name, :string)
    end

    create(unique_index(:servers, [:system_name]))
  end
end
