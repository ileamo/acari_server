defmodule AcariServer.ExportManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ExportManager

  describe "exports" do
    alias AcariServer.ExportManager.Export

    @valid_attrs %{common: true, name: "some name", profile: %{}}
    @update_attrs %{common: false, name: "some updated name", profile: %{}}
    @invalid_attrs %{common: nil, name: nil, profile: nil}

    def export_fixture(attrs \\ %{}) do
      {:ok, export} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ExportManager.create_export()

      export
    end

    test "list_exports/0 returns all exports" do
      export = export_fixture()
      assert ExportManager.list_exports() == [export]
    end

    test "get_export!/1 returns the export with given id" do
      export = export_fixture()
      assert ExportManager.get_export!(export.id) == export
    end

    test "create_export/1 with valid data creates a export" do
      assert {:ok, %Export{} = export} = ExportManager.create_export(@valid_attrs)
      assert export.common == true
      assert export.name == "some name"
      assert export.profile == %{}
    end

    test "create_export/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ExportManager.create_export(@invalid_attrs)
    end

    test "update_export/2 with valid data updates the export" do
      export = export_fixture()
      assert {:ok, %Export{} = export} = ExportManager.update_export(export, @update_attrs)
      assert export.common == false
      assert export.name == "some updated name"
      assert export.profile == %{}
    end

    test "update_export/2 with invalid data returns error changeset" do
      export = export_fixture()
      assert {:error, %Ecto.Changeset{}} = ExportManager.update_export(export, @invalid_attrs)
      assert export == ExportManager.get_export!(export.id)
    end

    test "delete_export/1 deletes the export" do
      export = export_fixture()
      assert {:ok, %Export{}} = ExportManager.delete_export(export)
      assert_raise Ecto.NoResultsError, fn -> ExportManager.get_export!(export.id) end
    end

    test "change_export/1 returns a export changeset" do
      export = export_fixture()
      assert %Ecto.Changeset{} = ExportManager.change_export(export)
    end
  end
end
