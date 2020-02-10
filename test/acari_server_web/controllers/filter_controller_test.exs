defmodule AcariServerWeb.FilterControllerTest do
  use AcariServerWeb.ConnCase

  alias AcariServer.FilterManager

  @create_attrs %{common: true, description: "some description", filter: "some filter"}
  @update_attrs %{common: false, description: "some updated description", filter: "some updated filter"}
  @invalid_attrs %{common: nil, description: nil, filter: nil}

  def fixture(:filter) do
    {:ok, filter} = FilterManager.create_filter(@create_attrs)
    filter
  end

  describe "index" do
    test "lists all filrers", %{conn: conn} do
      conn = get(conn, Routes.filter_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Filrers"
    end
  end

  describe "new filter" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.filter_path(conn, :new))
      assert html_response(conn, 200) =~ "New Filter"
    end
  end

  describe "create filter" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.filter_path(conn, :create), filter: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.filter_path(conn, :show, id)

      conn = get(conn, Routes.filter_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Filter"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.filter_path(conn, :create), filter: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Filter"
    end
  end

  describe "edit filter" do
    setup [:create_filter]

    test "renders form for editing chosen filter", %{conn: conn, filter: filter} do
      conn = get(conn, Routes.filter_path(conn, :edit, filter))
      assert html_response(conn, 200) =~ "Edit Filter"
    end
  end

  describe "update filter" do
    setup [:create_filter]

    test "redirects when data is valid", %{conn: conn, filter: filter} do
      conn = put(conn, Routes.filter_path(conn, :update, filter), filter: @update_attrs)
      assert redirected_to(conn) == Routes.filter_path(conn, :show, filter)

      conn = get(conn, Routes.filter_path(conn, :show, filter))
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, filter: filter} do
      conn = put(conn, Routes.filter_path(conn, :update, filter), filter: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Filter"
    end
  end

  describe "delete filter" do
    setup [:create_filter]

    test "deletes chosen filter", %{conn: conn, filter: filter} do
      conn = delete(conn, Routes.filter_path(conn, :delete, filter))
      assert redirected_to(conn) == Routes.filter_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.filter_path(conn, :show, filter))
      end
    end
  end

  defp create_filter(_) do
    filter = fixture(:filter)
    {:ok, filter: filter}
  end
end
