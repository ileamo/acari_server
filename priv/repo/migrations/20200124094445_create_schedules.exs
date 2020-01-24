defmodule AcariServer.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add :schedule, :string
      add :template_id, references(:templates, on_delete: :nothing)
      add :group_id, references(:groups, on_delete: :nothing)
      add :script_id, references(:scripts, on_delete: :nothing)

      timestamps()
    end

    create index(:schedules, [:template_id])
    create index(:schedules, [:group_id])
    create index(:schedules, [:script_id])
  end
end
