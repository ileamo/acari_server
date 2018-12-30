defmodule AcariServer.GroupManagerTest do
  use AcariServer.DataCase

  alias AcariServer.GroupManager

  describe "groups" do
    alias AcariServer.GroupManager.Group

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> GroupManager.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert GroupManager.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert GroupManager.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = GroupManager.create_group(@valid_attrs)
      assert group.description == "some description"
      assert group.name == "some name"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GroupManager.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, %Group{} = group} = GroupManager.update_group(group, @update_attrs)
      assert group.description == "some updated description"
      assert group.name == "some updated name"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = GroupManager.update_group(group, @invalid_attrs)
      assert group == GroupManager.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = GroupManager.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> GroupManager.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = GroupManager.change_group(group)
    end
  end
end
