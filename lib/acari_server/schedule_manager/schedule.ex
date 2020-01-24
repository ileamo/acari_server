defmodule AcariServer.ScheduleManager.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :schedule, :string
    belongs_to :template, AcariServer.TemplateManager.Template
    belongs_to :group, AcariServer.GroupManager.Group
    belongs_to :script, AcariServer.ScriptManager.Script

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:schedule])
    |> validate_required([:schedule])
  end
end
