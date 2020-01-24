defmodule AcariServer.ScheduleManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ScheduleManager

  describe "schedules" do
    alias AcariServer.ScheduleManager.Schedule

    @valid_attrs %{schedule: "some schedule"}
    @update_attrs %{schedule: "some updated schedule"}
    @invalid_attrs %{schedule: nil}

    def schedule_fixture(attrs \\ %{}) do
      {:ok, schedule} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ScheduleManager.create_schedule()

      schedule
    end

    test "list_schedules/0 returns all schedules" do
      schedule = schedule_fixture()
      assert ScheduleManager.list_schedules() == [schedule]
    end

    test "get_schedule!/1 returns the schedule with given id" do
      schedule = schedule_fixture()
      assert ScheduleManager.get_schedule!(schedule.id) == schedule
    end

    test "create_schedule/1 with valid data creates a schedule" do
      assert {:ok, %Schedule{} = schedule} = ScheduleManager.create_schedule(@valid_attrs)
      assert schedule.schedule == "some schedule"
    end

    test "create_schedule/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ScheduleManager.create_schedule(@invalid_attrs)
    end

    test "update_schedule/2 with valid data updates the schedule" do
      schedule = schedule_fixture()
      assert {:ok, %Schedule{} = schedule} = ScheduleManager.update_schedule(schedule, @update_attrs)
      assert schedule.schedule == "some updated schedule"
    end

    test "update_schedule/2 with invalid data returns error changeset" do
      schedule = schedule_fixture()
      assert {:error, %Ecto.Changeset{}} = ScheduleManager.update_schedule(schedule, @invalid_attrs)
      assert schedule == ScheduleManager.get_schedule!(schedule.id)
    end

    test "delete_schedule/1 deletes the schedule" do
      schedule = schedule_fixture()
      assert {:ok, %Schedule{}} = ScheduleManager.delete_schedule(schedule)
      assert_raise Ecto.NoResultsError, fn -> ScheduleManager.get_schedule!(schedule.id) end
    end

    test "change_schedule/1 returns a schedule changeset" do
      schedule = schedule_fixture()
      assert %Ecto.Changeset{} = ScheduleManager.change_schedule(schedule)
    end
  end
end
