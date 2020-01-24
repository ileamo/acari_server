defmodule AcariServer.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add(:schedule, :string)
      add(:description, :string)
      add(:template_id, references(:templates, on_delete: :delete_all), null: false)
      add(:group_id, references(:groups, on_delete: :delete_all))
      add(:script_id, references(:scripts, on_delete: :delete_all))

      timestamps()
    end

    create(index(:schedules, [:template_id]))
    create(index(:schedules, [:group_id]))
    create(index(:schedules, [:script_id]))
  end
end
