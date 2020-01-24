defmodule AcariServer.ScheduleManager.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :schedule, :string
    field :description, :string
    belongs_to :template, AcariServer.TemplateManager.Template
    belongs_to :group, AcariServer.GroupManager.Group
    belongs_to :script, AcariServer.ScriptManager.Script

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:schedule, :description, :template_id, :group_id, :script_id])
    |> validate_required([:schedule])
    |> validate_change(:schedule, &validate_schedule/2)
    |> foreign_key_constraint(:template_id)
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:script_id)
  end

  defp validate_schedule(:schedule, sched) do
    case Crontab.CronExpression.Parser.parse(sched) do
      {:ok, _} ->
        []

      {:error, mes} ->
        [schedule: mes]
    end
  end
end
