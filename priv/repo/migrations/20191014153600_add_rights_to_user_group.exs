defmodule AcariServer.Repo.Migrations.AddRightsToUserGroup do
  use Ecto.Migration

  def change do
    alter table(:groups_users) do
      add(:rights, :string, default: nil)
    end
  end
end
