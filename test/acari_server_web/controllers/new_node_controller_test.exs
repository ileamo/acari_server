defmodule AcariServerWeb.NewNodeControllerTest do
  use AcariServerWeb.ConnCase

  alias AcariServer.NewNodeDiscovery

  @create_attrs %{ip_addr: "some ip_addr", name: "some name", params: %{}, template: "some template"}
  @update_attrs %{ip_addr: "some updated ip_addr", name: "some updated name", params: %{}, template: "some updated template"}
  @invalid_attrs %{ip_addr: nil, name: nil, params: nil, template: nil}

  def fixture(:new_node) do
    {:ok, new_node} = NewNodeDiscovery.create_new_node(@create_attrs)
    new_node
  end

  describe "index" do
    test "lists all newnodes", %{conn: conn} do
      conn = get(conn, Routes.new_node_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Newnodes"
    end
  end

  describe "new new_node" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.new_node_path(conn, :new))
      assert html_response(conn, 200) =~ "New New node"
    end
  end

  describe "create new_node" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.new_node_path(conn, :create), new_node: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.new_node_path(conn, :show, id)

      conn = get(conn, Routes.new_node_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show New node"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.new_node_path(conn, :create), new_node: @invalid_attrs)
      assert html_response(conn, 200) =~ "New New node"
    end
  end

  describe "edit new_node" do
    setup [:create_new_node]

    test "renders form for editing chosen new_node", %{conn: conn, new_node: new_node} do
      conn = get(conn, Routes.new_node_path(conn, :edit, new_node))
      assert html_response(conn, 200) =~ "Edit New node"
    end
  end

  describe "update new_node" do
    setup [:create_new_node]

    test "redirects when data is valid", %{conn: conn, new_node: new_node} do
      conn = put(conn, Routes.new_node_path(conn, :update, new_node), new_node: @update_attrs)
      assert redirected_to(conn) == Routes.new_node_path(conn, :show, new_node)

      conn = get(conn, Routes.new_node_path(conn, :show, new_node))
      assert html_response(conn, 200) =~ "some updated ip_addr"
    end

    test "renders errors when data is invalid", %{conn: conn, new_node: new_node} do
      conn = put(conn, Routes.new_node_path(conn, :update, new_node), new_node: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit New node"
    end
  end

  describe "delete new_node" do
    setup [:create_new_node]

    test "deletes chosen new_node", %{conn: conn, new_node: new_node} do
      conn = delete(conn, Routes.new_node_path(conn, :delete, new_node))
      assert redirected_to(conn) == Routes.new_node_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.new_node_path(conn, :show, new_node))
      end
    end
  end

  defp create_new_node(_) do
    new_node = fixture(:new_node)
    {:ok, new_node: new_node}
  end
end
