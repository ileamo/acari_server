defmodule AcariServer.ChatManagerTest do
  use AcariServer.DataCase

  alias AcariServer.ChatManager

  describe "chat_messages" do
    alias AcariServer.ChatManager.Chat

    @valid_attrs %{message: "some message"}
    @update_attrs %{message: "some updated message"}
    @invalid_attrs %{message: nil}

    def chat_fixture(attrs \\ %{}) do
      {:ok, chat} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ChatManager.create_chat()

      chat
    end

    test "list_chat_messages/0 returns all chat_messages" do
      chat = chat_fixture()
      assert ChatManager.list_chat_messages() == [chat]
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert ChatManager.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with valid data creates a chat" do
      assert {:ok, %Chat{} = chat} = ChatManager.create_chat(@valid_attrs)
      assert chat.message == "some message"
    end

    test "create_chat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ChatManager.create_chat(@invalid_attrs)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      assert {:ok, %Chat{} = chat} = ChatManager.update_chat(chat, @update_attrs)
      assert chat.message == "some updated message"
    end

    test "update_chat/2 with invalid data returns error changeset" do
      chat = chat_fixture()
      assert {:error, %Ecto.Changeset{}} = ChatManager.update_chat(chat, @invalid_attrs)
      assert chat == ChatManager.get_chat!(chat.id)
    end

    test "delete_chat/1 deletes the chat" do
      chat = chat_fixture()
      assert {:ok, %Chat{}} = ChatManager.delete_chat(chat)
      assert_raise Ecto.NoResultsError, fn -> ChatManager.get_chat!(chat.id) end
    end

    test "change_chat/1 returns a chat changeset" do
      chat = chat_fixture()
      assert %Ecto.Changeset{} = ChatManager.change_chat(chat)
    end
  end
end
