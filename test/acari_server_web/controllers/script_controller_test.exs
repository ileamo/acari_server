defmodule AcariServerWeb.ScriptControllerTest do
  use AcariServerWeb.ConnCase

  alias AcariServer.ScriptManager

  @create_attrs %{local: "some local", name: "some name", remote: "some remote"}
  @update_attrs %{local: "some updated local", name: "some updated name", remote: "some updated remote"}
  @invalid_attrs %{local: nil, name: nil, remote: nil}

  def fixture(:script) do
    {:ok, script} = ScriptManager.create_script(@create_attrs)
    script
  end

  describe "index" do
    test "lists all scripts", %{conn: conn} do
      conn = get(conn, Routes.script_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Scripts"
    end
  end

  describe "new script" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.script_path(conn, :new))
      assert html_response(conn, 200) =~ "New Script"
    end
  end

  describe "create script" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.script_path(conn, :create), script: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.script_path(conn, :show, id)

      conn = get(conn, Routes.script_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Script"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.script_path(conn, :create), script: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Script"
    end
  end

  describe "edit script" do
    setup [:create_script]

    test "renders form for editing chosen script", %{conn: conn, script: script} do
      conn = get(conn, Routes.script_path(conn, :edit, script))
      assert html_response(conn, 200) =~ "Edit Script"
    end
  end

  describe "update script" do
    setup [:create_script]

    test "redirects when data is valid", %{conn: conn, script: script} do
      conn = put(conn, Routes.script_path(conn, :update, script), script: @update_attrs)
      assert redirected_to(conn) == Routes.script_path(conn, :show, script)

      conn = get(conn, Routes.script_path(conn, :show, script))
      assert html_response(conn, 200) =~ "some updated local"
    end

    test "renders errors when data is invalid", %{conn: conn, script: script} do
      conn = put(conn, Routes.script_path(conn, :update, script), script: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Script"
    end
  end

  describe "delete script" do
    setup [:create_script]

    test "deletes chosen script", %{conn: conn, script: script} do
      conn = delete(conn, Routes.script_path(conn, :delete, script))
      assert redirected_to(conn) == Routes.script_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.script_path(conn, :show, script))
      end
    end
  end

  defp create_script(_) do
    script = fixture(:script)
    {:ok, script: script}
  end
end
