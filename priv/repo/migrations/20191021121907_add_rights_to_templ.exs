defmodule AcariServer.Repo.Migrations.AddRightsToTempl do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:rights, :string, default: "rw")
    end
  end
end
