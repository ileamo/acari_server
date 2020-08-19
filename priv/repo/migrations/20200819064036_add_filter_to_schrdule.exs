defmodule AcariServer.Repo.Migrations.AddFilterToSchrdule do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add(:filter, :text, default: "")
    end
  end
end
