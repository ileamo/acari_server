defmodule AcariServer.NodeManagerTest do
  use AcariServer.DataCase

  alias AcariServer.NodeManager

  describe "nodes" do
    alias AcariServer.NodeManager.Node

    @valid_attrs %{description: "some description", name: "some name", params: %{}, sn: "some sn"}
    @update_attrs %{
      description: "some updated description",
      name: "some updated name",
      params: %{},
      sn: "some updated sn"
    }
    @invalid_attrs %{description: nil, name: nil, params: nil, sn: nil}

    def node_fixture(attrs \\ %{}) do
      {:ok, node} =
        attrs
        |> Enum.into(@valid_attrs)
        |> NodeManager.create_node()

      node
    end

    test "list_nodes/0 returns all nodes" do
      node = node_fixture()
      assert NodeManager.list_nodes() == [node]
    end

    test "get_node!/1 returns the node with given id" do
      node = node_fixture()
      assert NodeManager.get_node!(node.id) == node
    end

    test "create_node/1 with valid data creates a node" do
      assert {:ok, %Node{} = node} = NodeManager.create_node(@valid_attrs)
      assert node.description == "some description"
      assert node.name == "some name"
      assert node.params == %{}
      assert node.sn == "some sn"
    end

    test "create_node/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NodeManager.create_node(@invalid_attrs)
    end

    test "update_node/2 with valid data updates the node" do
      node = node_fixture()
      assert {:ok, %Node{} = node} = NodeManager.update_node(node, @update_attrs)
      assert node.description == "some updated description"
      assert node.name == "some updated name"
      assert node.params == %{}
      assert node.sn == "some updated sn"
    end

    test "update_node/2 with invalid data returns error changeset" do
      node = node_fixture()
      assert {:error, %Ecto.Changeset{}} = NodeManager.update_node(node, @invalid_attrs)
      assert node == NodeManager.get_node!(node.id)
    end

    test "delete_node/1 deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = NodeManager.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> NodeManager.get_node!(node.id) end
    end

    test "change_node/1 returns a node changeset" do
      node = node_fixture()
      assert %Ecto.Changeset{} = NodeManager.change_node(node)
    end
  end
end
