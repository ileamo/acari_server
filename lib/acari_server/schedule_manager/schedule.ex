defmodule AcariServer.ScheduleManager.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :schedule, :string
    field :template_id, :id
    field :group_id, :id
    field :script_id, :id

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:schedule])
    |> validate_required([:schedule])
  end
end
