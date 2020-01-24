defmodule AcariServerWeb.ScheduleControllerTest do
  use AcariServerWeb.ConnCase

  alias AcariServer.ScheduleManager

  @create_attrs %{schedule: "some schedule"}
  @update_attrs %{schedule: "some updated schedule"}
  @invalid_attrs %{schedule: nil}

  def fixture(:schedule) do
    {:ok, schedule} = ScheduleManager.create_schedule(@create_attrs)
    schedule
  end

  describe "index" do
    test "lists all schedules", %{conn: conn} do
      conn = get(conn, Routes.schedule_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Schedules"
    end
  end

  describe "new schedule" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.schedule_path(conn, :new))
      assert html_response(conn, 200) =~ "New Schedule"
    end
  end

  describe "create schedule" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.schedule_path(conn, :create), schedule: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.schedule_path(conn, :show, id)

      conn = get(conn, Routes.schedule_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Schedule"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.schedule_path(conn, :create), schedule: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Schedule"
    end
  end

  describe "edit schedule" do
    setup [:create_schedule]

    test "renders form for editing chosen schedule", %{conn: conn, schedule: schedule} do
      conn = get(conn, Routes.schedule_path(conn, :edit, schedule))
      assert html_response(conn, 200) =~ "Edit Schedule"
    end
  end

  describe "update schedule" do
    setup [:create_schedule]

    test "redirects when data is valid", %{conn: conn, schedule: schedule} do
      conn = put(conn, Routes.schedule_path(conn, :update, schedule), schedule: @update_attrs)
      assert redirected_to(conn) == Routes.schedule_path(conn, :show, schedule)

      conn = get(conn, Routes.schedule_path(conn, :show, schedule))
      assert html_response(conn, 200) =~ "some updated schedule"
    end

    test "renders errors when data is invalid", %{conn: conn, schedule: schedule} do
      conn = put(conn, Routes.schedule_path(conn, :update, schedule), schedule: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Schedule"
    end
  end

  describe "delete schedule" do
    setup [:create_schedule]

    test "deletes chosen schedule", %{conn: conn, schedule: schedule} do
      conn = delete(conn, Routes.schedule_path(conn, :delete, schedule))
      assert redirected_to(conn) == Routes.schedule_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.schedule_path(conn, :show, schedule))
      end
    end
  end

  defp create_schedule(_) do
    schedule = fixture(:schedule)
    {:ok, schedule: schedule}
  end
end
