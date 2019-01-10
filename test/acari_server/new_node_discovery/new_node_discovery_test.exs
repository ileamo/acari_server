defmodule AcariServer.NewNodeDiscoveryTest do
  use AcariServer.DataCase

  alias AcariServer.NewNodeDiscovery

  describe "newnodes" do
    alias AcariServer.NewNodeDiscovery.NewNode

    @valid_attrs %{ip_addr: "some ip_addr", name: "some name", params: %{}, template: "some template"}
    @update_attrs %{ip_addr: "some updated ip_addr", name: "some updated name", params: %{}, template: "some updated template"}
    @invalid_attrs %{ip_addr: nil, name: nil, params: nil, template: nil}

    def new_node_fixture(attrs \\ %{}) do
      {:ok, new_node} =
        attrs
        |> Enum.into(@valid_attrs)
        |> NewNodeDiscovery.create_new_node()

      new_node
    end

    test "list_newnodes/0 returns all newnodes" do
      new_node = new_node_fixture()
      assert NewNodeDiscovery.list_newnodes() == [new_node]
    end

    test "get_new_node!/1 returns the new_node with given id" do
      new_node = new_node_fixture()
      assert NewNodeDiscovery.get_new_node!(new_node.id) == new_node
    end

    test "create_new_node/1 with valid data creates a new_node" do
      assert {:ok, %NewNode{} = new_node} = NewNodeDiscovery.create_new_node(@valid_attrs)
      assert new_node.ip_addr == "some ip_addr"
      assert new_node.name == "some name"
      assert new_node.params == %{}
      assert new_node.template == "some template"
    end

    test "create_new_node/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NewNodeDiscovery.create_new_node(@invalid_attrs)
    end

    test "update_new_node/2 with valid data updates the new_node" do
      new_node = new_node_fixture()
      assert {:ok, %NewNode{} = new_node} = NewNodeDiscovery.update_new_node(new_node, @update_attrs)
      assert new_node.ip_addr == "some updated ip_addr"
      assert new_node.name == "some updated name"
      assert new_node.params == %{}
      assert new_node.template == "some updated template"
    end

    test "update_new_node/2 with invalid data returns error changeset" do
      new_node = new_node_fixture()
      assert {:error, %Ecto.Changeset{}} = NewNodeDiscovery.update_new_node(new_node, @invalid_attrs)
      assert new_node == NewNodeDiscovery.get_new_node!(new_node.id)
    end

    test "delete_new_node/1 deletes the new_node" do
      new_node = new_node_fixture()
      assert {:ok, %NewNode{}} = NewNodeDiscovery.delete_new_node(new_node)
      assert_raise Ecto.NoResultsError, fn -> NewNodeDiscovery.get_new_node!(new_node.id) end
    end

    test "change_new_node/1 returns a new_node changeset" do
      new_node = new_node_fixture()
      assert %Ecto.Changeset{} = NewNodeDiscovery.change_new_node(new_node)
    end
  end
end
