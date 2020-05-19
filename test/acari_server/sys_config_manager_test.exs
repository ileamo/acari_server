defmodule AcariServer.SysConfigManagerTest do
  use AcariServer.DataCase

  alias AcariServer.SysConfigManager

  describe "sysconfigs" do
    alias AcariServer.SysConfigManager.SysConfig

    @valid_attrs %{name: "some name", value: "some value"}
    @update_attrs %{name: "some updated name", value: "some updated value"}
    @invalid_attrs %{name: nil, value: nil}

    def sys_config_fixture(attrs \\ %{}) do
      {:ok, sys_config} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SysConfigManager.create_sys_config()

      sys_config
    end

    test "list_sysconfigs/0 returns all sysconfigs" do
      sys_config = sys_config_fixture()
      assert SysConfigManager.list_sysconfigs() == [sys_config]
    end

    test "get_sys_config!/1 returns the sys_config with given id" do
      sys_config = sys_config_fixture()
      assert SysConfigManager.get_sys_config!(sys_config.id) == sys_config
    end

    test "create_sys_config/1 with valid data creates a sys_config" do
      assert {:ok, %SysConfig{} = sys_config} = SysConfigManager.create_sys_config(@valid_attrs)
      assert sys_config.name == "some name"
      assert sys_config.value == "some value"
    end

    test "create_sys_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SysConfigManager.create_sys_config(@invalid_attrs)
    end

    test "update_sys_config/2 with valid data updates the sys_config" do
      sys_config = sys_config_fixture()
      assert {:ok, %SysConfig{} = sys_config} = SysConfigManager.update_sys_config(sys_config, @update_attrs)
      assert sys_config.name == "some updated name"
      assert sys_config.value == "some updated value"
    end

    test "update_sys_config/2 with invalid data returns error changeset" do
      sys_config = sys_config_fixture()
      assert {:error, %Ecto.Changeset{}} = SysConfigManager.update_sys_config(sys_config, @invalid_attrs)
      assert sys_config == SysConfigManager.get_sys_config!(sys_config.id)
    end

    test "delete_sys_config/1 deletes the sys_config" do
      sys_config = sys_config_fixture()
      assert {:ok, %SysConfig{}} = SysConfigManager.delete_sys_config(sys_config)
      assert_raise Ecto.NoResultsError, fn -> SysConfigManager.get_sys_config!(sys_config.id) end
    end

    test "change_sys_config/1 returns a sys_config changeset" do
      sys_config = sys_config_fixture()
      assert %Ecto.Changeset{} = SysConfigManager.change_sys_config(sys_config)
    end
  end
end
