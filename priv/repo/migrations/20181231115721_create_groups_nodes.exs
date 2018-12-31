defmodule AcariServer.Repo.Migrations.CreateGroupsNodes do
  use Ecto.Migration

  def change do
    create table(:groups_nodes) do

      timestamps()
    end

  end
end
