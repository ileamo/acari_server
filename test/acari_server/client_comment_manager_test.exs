defmodule AcariServer.ClientCommentManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ClientCommentManager

  describe "client_comments" do
    alias AcariServer.ClientCommentManager.ClientComment

    @valid_attrs %{comment: "some comment"}
    @update_attrs %{comment: "some updated comment"}
    @invalid_attrs %{comment: nil}

    def client_comment_fixture(attrs \\ %{}) do
      {:ok, client_comment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ClientCommentManager.create_client_comment()

      client_comment
    end

    test "list_client_comments/0 returns all client_comments" do
      client_comment = client_comment_fixture()
      assert ClientCommentManager.list_client_comments() == [client_comment]
    end

    test "get_client_comment!/1 returns the client_comment with given id" do
      client_comment = client_comment_fixture()
      assert ClientCommentManager.get_client_comment!(client_comment.id) == client_comment
    end

    test "create_client_comment/1 with valid data creates a client_comment" do
      assert {:ok, %ClientComment{} = client_comment} = ClientCommentManager.create_client_comment(@valid_attrs)
      assert client_comment.comment == "some comment"
    end

    test "create_client_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ClientCommentManager.create_client_comment(@invalid_attrs)
    end

    test "update_client_comment/2 with valid data updates the client_comment" do
      client_comment = client_comment_fixture()
      assert {:ok, %ClientComment{} = client_comment} = ClientCommentManager.update_client_comment(client_comment, @update_attrs)
      assert client_comment.comment == "some updated comment"
    end

    test "update_client_comment/2 with invalid data returns error changeset" do
      client_comment = client_comment_fixture()
      assert {:error, %Ecto.Changeset{}} = ClientCommentManager.update_client_comment(client_comment, @invalid_attrs)
      assert client_comment == ClientCommentManager.get_client_comment!(client_comment.id)
    end

    test "delete_client_comment/1 deletes the client_comment" do
      client_comment = client_comment_fixture()
      assert {:ok, %ClientComment{}} = ClientCommentManager.delete_client_comment(client_comment)
      assert_raise Ecto.NoResultsError, fn -> ClientCommentManager.get_client_comment!(client_comment.id) end
    end

    test "change_client_comment/1 returns a client_comment changeset" do
      client_comment = client_comment_fixture()
      assert %Ecto.Changeset{} = ClientCommentManager.change_client_comment(client_comment)
    end
  end
end
