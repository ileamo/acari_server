defmodule AcariServer.ServerManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ServerManager

  describe "servers" do
    alias AcariServer.ServerManager.Server

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    def server_fixture(attrs \\ %{}) do
      {:ok, server} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ServerManager.create_server()

      server
    end

    test "list_servers/0 returns all servers" do
      server = server_fixture()
      assert ServerManager.list_servers() == [server]
    end

    test "get_server!/1 returns the server with given id" do
      server = server_fixture()
      assert ServerManager.get_server!(server.id) == server
    end

    test "create_server/1 with valid data creates a server" do
      assert {:ok, %Server{} = server} = ServerManager.create_server(@valid_attrs)
      assert server.description == "some description"
      assert server.name == "some name"
    end

    test "create_server/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ServerManager.create_server(@invalid_attrs)
    end

    test "update_server/2 with valid data updates the server" do
      server = server_fixture()
      assert {:ok, %Server{} = server} = ServerManager.update_server(server, @update_attrs)
      assert server.description == "some updated description"
      assert server.name == "some updated name"
    end

    test "update_server/2 with invalid data returns error changeset" do
      server = server_fixture()
      assert {:error, %Ecto.Changeset{}} = ServerManager.update_server(server, @invalid_attrs)
      assert server == ServerManager.get_server!(server.id)
    end

    test "delete_server/1 deletes the server" do
      server = server_fixture()
      assert {:ok, %Server{}} = ServerManager.delete_server(server)
      assert_raise Ecto.NoResultsError, fn -> ServerManager.get_server!(server.id) end
    end

    test "change_server/1 returns a server changeset" do
      server = server_fixture()
      assert %Ecto.Changeset{} = ServerManager.change_server(server)
    end
  end
end
