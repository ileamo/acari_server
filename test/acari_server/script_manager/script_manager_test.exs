defmodule AcariServer.ScriptManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ScriptManager

  describe "scripts" do
    alias AcariServer.ScriptManager.Script

    @valid_attrs %{local: "some local", name: "some name", remote: "some remote"}
    @update_attrs %{local: "some updated local", name: "some updated name", remote: "some updated remote"}
    @invalid_attrs %{local: nil, name: nil, remote: nil}

    def script_fixture(attrs \\ %{}) do
      {:ok, script} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ScriptManager.create_script()

      script
    end

    test "list_scripts/0 returns all scripts" do
      script = script_fixture()
      assert ScriptManager.list_scripts() == [script]
    end

    test "get_script!/1 returns the script with given id" do
      script = script_fixture()
      assert ScriptManager.get_script!(script.id) == script
    end

    test "create_script/1 with valid data creates a script" do
      assert {:ok, %Script{} = script} = ScriptManager.create_script(@valid_attrs)
      assert script.local == "some local"
      assert script.name == "some name"
      assert script.remote == "some remote"
    end

    test "create_script/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ScriptManager.create_script(@invalid_attrs)
    end

    test "update_script/2 with valid data updates the script" do
      script = script_fixture()
      assert {:ok, %Script{} = script} = ScriptManager.update_script(script, @update_attrs)
      assert script.local == "some updated local"
      assert script.name == "some updated name"
      assert script.remote == "some updated remote"
    end

    test "update_script/2 with invalid data returns error changeset" do
      script = script_fixture()
      assert {:error, %Ecto.Changeset{}} = ScriptManager.update_script(script, @invalid_attrs)
      assert script == ScriptManager.get_script!(script.id)
    end

    test "delete_script/1 deletes the script" do
      script = script_fixture()
      assert {:ok, %Script{}} = ScriptManager.delete_script(script)
      assert_raise Ecto.NoResultsError, fn -> ScriptManager.get_script!(script.id) end
    end

    test "change_script/1 returns a script changeset" do
      script = script_fixture()
      assert %Ecto.Changeset{} = ScriptManager.change_script(script)
    end
  end
end
