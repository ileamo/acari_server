defmodule AcariServer.ScheduleManager do
  @moduledoc """
  The ScheduleManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.ScheduleManager.Schedule

  @doc """
  Returns the list of schedules.

  ## Examples

      iex> list_schedules()
      [%Schedule{}, ...]

  """
  def list_schedules do
    RepoRO.all(Schedule)
    |> RepoRO.preload(:template)
    |> RepoRO.preload(:group)
    |> RepoRO.preload(:script)
  end

  @doc """
  Gets a single schedule.

  Raises `Ecto.NoResultsError` if the Schedule does not exist.

  ## Examples

      iex> get_schedule!(123)
      %Schedule{}

      iex> get_schedule!(456)
      ** (Ecto.NoResultsError)

  """
  def get_schedule!(id) do
    RepoRO.get!(Schedule, id)
    |> RepoRO.preload(:template)
    |> RepoRO.preload(:group)
    |> RepoRO.preload(:script)
  end

  def get_schedule(id) do
    RepoRO.get(Schedule, id)
    |> RepoRO.preload(:template)
    |> RepoRO.preload(:group)
  end

  @doc """
  Creates a schedule.

  ## Examples

      iex> create_schedule(%{field: value})
      {:ok, %Schedule{}}

      iex> create_schedule(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_schedule(attrs \\ %{}) do
    res =
      %Schedule{}
      |> Schedule.changeset(attrs)
      |> Repo.insert()

    case res do
      {:ok, schedule} ->
        AcariServer.Scheduler.Api.quantum_apply(:add_job, [schedule])
        res

      _ ->
        res
    end
  end

  @doc """
  Updates a schedule.

  ## Examples

      iex> update_schedule(schedule, %{field: new_value})
      {:ok, %Schedule{}}

      iex> update_schedule(schedule, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_schedule(%Schedule{} = schedule, attrs) do
    res =
      schedule
      |> Schedule.changeset(attrs)
      |> Repo.update()

    case res do
      {:ok, updated_schedule} ->
        AcariServer.Scheduler.Api.quantum_apply(:update_job, [updated_schedule])

        res

      _ ->
        res
    end
  end

  @doc """
  Deletes a Schedule.

  ## Examples

      iex> delete_schedule(schedule)
      {:ok, %Schedule{}}

      iex> delete_schedule(schedule)
      {:error, %Ecto.Changeset{}}

  """
  def delete_schedule(%Schedule{} = schedule) do
    res = Repo.delete(schedule)
    AcariServer.Scheduler.Api.quantum_apply(:update_script_jobs)
    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking schedule changes.

  ## Examples

      iex> change_schedule(schedule)
      %Ecto.Changeset{source: %Schedule{}}

  """
  def change_schedule(%Schedule{} = schedule) do
    Schedule.changeset(schedule, %{})
  end
end
