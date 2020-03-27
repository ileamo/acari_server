defmodule AcariServer.Repo.Migrations.AddTypeToTempl do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:type, :string, default: "no")
    end
  end
end
