defmodule AcariServerWeb.AuditControllerTest do
  use AcariServerWeb.ConnCase

  alias AcariServer.AuditManager

  @create_attrs %{object: "some object", object_name: "some object_name", operation: "some operation", params: "some params", username: "some username"}
  @update_attrs %{object: "some updated object", object_name: "some updated object_name", operation: "some updated operation", params: "some updated params", username: "some updated username"}
  @invalid_attrs %{object: nil, object_name: nil, operation: nil, params: nil, username: nil}

  def fixture(:audit) do
    {:ok, audit} = AuditManager.create_audit(@create_attrs)
    audit
  end

  describe "index" do
    test "lists all audit_logs", %{conn: conn} do
      conn = get(conn, Routes.audit_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Audit logs"
    end
  end

  describe "new audit" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.audit_path(conn, :new))
      assert html_response(conn, 200) =~ "New Audit"
    end
  end

  describe "create audit" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.audit_path(conn, :create), audit: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.audit_path(conn, :show, id)

      conn = get(conn, Routes.audit_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Audit"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.audit_path(conn, :create), audit: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Audit"
    end
  end

  describe "edit audit" do
    setup [:create_audit]

    test "renders form for editing chosen audit", %{conn: conn, audit: audit} do
      conn = get(conn, Routes.audit_path(conn, :edit, audit))
      assert html_response(conn, 200) =~ "Edit Audit"
    end
  end

  describe "update audit" do
    setup [:create_audit]

    test "redirects when data is valid", %{conn: conn, audit: audit} do
      conn = put(conn, Routes.audit_path(conn, :update, audit), audit: @update_attrs)
      assert redirected_to(conn) == Routes.audit_path(conn, :show, audit)

      conn = get(conn, Routes.audit_path(conn, :show, audit))
      assert html_response(conn, 200) =~ "some updated object"
    end

    test "renders errors when data is invalid", %{conn: conn, audit: audit} do
      conn = put(conn, Routes.audit_path(conn, :update, audit), audit: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Audit"
    end
  end

  describe "delete audit" do
    setup [:create_audit]

    test "deletes chosen audit", %{conn: conn, audit: audit} do
      conn = delete(conn, Routes.audit_path(conn, :delete, audit))
      assert redirected_to(conn) == Routes.audit_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.audit_path(conn, :show, audit))
      end
    end
  end

  defp create_audit(_) do
    audit = fixture(:audit)
    {:ok, audit: audit}
  end
end
