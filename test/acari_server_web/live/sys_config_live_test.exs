defmodule AcariServerWeb.SysConfigLiveTest do
  use AcariServerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias AcariServer.SysConfigManager

  @create_attrs %{name: "some name", value: "some value"}
  @update_attrs %{name: "some updated name", value: "some updated value"}
  @invalid_attrs %{name: nil, value: nil}

  defp fixture(:sys_config) do
    {:ok, sys_config} = SysConfigManager.create_sys_config(@create_attrs)
    sys_config
  end

  defp create_sys_config(_) do
    sys_config = fixture(:sys_config)
    %{sys_config: sys_config}
  end

  describe "Index" do
    setup [:create_sys_config]

    test "lists all sysconfigs", %{conn: conn, sys_config: sys_config} do
      {:ok, _index_live, html} = live(conn, Routes.sys_config_index_path(conn, :index))

      assert html =~ "Listing Sysconfigs"
      assert html =~ sys_config.name
    end

    test "saves new sys_config", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.sys_config_index_path(conn, :index))

      assert index_live |> element("a", "New Sys config") |> render_click() =~
        "New Sys config"

      assert_patch(index_live, Routes.sys_config_index_path(conn, :new))

      assert index_live
             |> form("#sys_config-form", sys_config: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#sys_config-form", sys_config: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.sys_config_index_path(conn, :index))

      assert html =~ "Sys config created successfully"
      assert html =~ "some name"
    end

    test "updates sys_config in listing", %{conn: conn, sys_config: sys_config} do
      {:ok, index_live, _html} = live(conn, Routes.sys_config_index_path(conn, :index))

      assert index_live |> element("#sys_config-#{sys_config.id} a", "Edit") |> render_click() =~
        "Edit Sys config"

      assert_patch(index_live, Routes.sys_config_index_path(conn, :edit, sys_config))

      assert index_live
             |> form("#sys_config-form", sys_config: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#sys_config-form", sys_config: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.sys_config_index_path(conn, :index))

      assert html =~ "Sys config updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes sys_config in listing", %{conn: conn, sys_config: sys_config} do
      {:ok, index_live, _html} = live(conn, Routes.sys_config_index_path(conn, :index))

      assert index_live |> element("#sys_config-#{sys_config.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#sys_config-#{sys_config.id}")
    end
  end

  describe "Show" do
    setup [:create_sys_config]

    test "displays sys_config", %{conn: conn, sys_config: sys_config} do
      {:ok, _show_live, html} = live(conn, Routes.sys_config_show_path(conn, :show, sys_config))

      assert html =~ "Show Sys config"
      assert html =~ sys_config.name
    end

    test "updates sys_config within modal", %{conn: conn, sys_config: sys_config} do
      {:ok, show_live, _html} = live(conn, Routes.sys_config_show_path(conn, :show, sys_config))

      assert show_live |> element("a", "Edit") |> render_click() =~
        "Edit Sys config"

      assert_patch(show_live, Routes.sys_config_show_path(conn, :edit, sys_config))

      assert show_live
             |> form("#sys_config-form", sys_config: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#sys_config-form", sys_config: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.sys_config_show_path(conn, :show, sys_config))

      assert html =~ "Sys config updated successfully"
      assert html =~ "some updated name"
    end
  end
end
