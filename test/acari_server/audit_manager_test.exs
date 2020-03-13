defmodule AcariServer.AuditManagerTest do
  use AcariServer.DataCase

  alias AcariServer.AuditManager

  describe "audit_logs" do
    alias AcariServer.AuditManager.Audit

    @valid_attrs %{object: "some object", object_name: "some object_name", operation: "some operation", params: "some params", username: "some username"}
    @update_attrs %{object: "some updated object", object_name: "some updated object_name", operation: "some updated operation", params: "some updated params", username: "some updated username"}
    @invalid_attrs %{object: nil, object_name: nil, operation: nil, params: nil, username: nil}

    def audit_fixture(attrs \\ %{}) do
      {:ok, audit} =
        attrs
        |> Enum.into(@valid_attrs)
        |> AuditManager.create_audit()

      audit
    end

    test "list_audit_logs/0 returns all audit_logs" do
      audit = audit_fixture()
      assert AuditManager.list_audit_logs() == [audit]
    end

    test "get_audit!/1 returns the audit with given id" do
      audit = audit_fixture()
      assert AuditManager.get_audit!(audit.id) == audit
    end

    test "create_audit/1 with valid data creates a audit" do
      assert {:ok, %Audit{} = audit} = AuditManager.create_audit(@valid_attrs)
      assert audit.object == "some object"
      assert audit.object_name == "some object_name"
      assert audit.operation == "some operation"
      assert audit.params == "some params"
      assert audit.username == "some username"
    end

    test "create_audit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AuditManager.create_audit(@invalid_attrs)
    end

    test "update_audit/2 with valid data updates the audit" do
      audit = audit_fixture()
      assert {:ok, %Audit{} = audit} = AuditManager.update_audit(audit, @update_attrs)
      assert audit.object == "some updated object"
      assert audit.object_name == "some updated object_name"
      assert audit.operation == "some updated operation"
      assert audit.params == "some updated params"
      assert audit.username == "some updated username"
    end

    test "update_audit/2 with invalid data returns error changeset" do
      audit = audit_fixture()
      assert {:error, %Ecto.Changeset{}} = AuditManager.update_audit(audit, @invalid_attrs)
      assert audit == AuditManager.get_audit!(audit.id)
    end

    test "delete_audit/1 deletes the audit" do
      audit = audit_fixture()
      assert {:ok, %Audit{}} = AuditManager.delete_audit(audit)
      assert_raise Ecto.NoResultsError, fn -> AuditManager.get_audit!(audit.id) end
    end

    test "change_audit/1 returns a audit changeset" do
      audit = audit_fixture()
      assert %Ecto.Changeset{} = AuditManager.change_audit(audit)
    end
  end
end
