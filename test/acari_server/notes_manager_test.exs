defmodule AcariServer.NotesManagerTest do
  use AcariServer.DataCase

  alias AcariServer.NotesManager

  describe "notes" do
    alias AcariServer.NotesManager.Note

    @valid_attrs %{body: "some body", subject: "some subject"}
    @update_attrs %{body: "some updated body", subject: "some updated subject"}
    @invalid_attrs %{body: nil, subject: nil}

    def note_fixture(attrs \\ %{}) do
      {:ok, note} =
        attrs
        |> Enum.into(@valid_attrs)
        |> NotesManager.create_note()

      note
    end

    test "list_notes/0 returns all notes" do
      note = note_fixture()
      assert NotesManager.list_notes() == [note]
    end

    test "get_note!/1 returns the note with given id" do
      note = note_fixture()
      assert NotesManager.get_note!(note.id) == note
    end

    test "create_note/1 with valid data creates a note" do
      assert {:ok, %Note{} = note} = NotesManager.create_note(@valid_attrs)
      assert note.body == "some body"
      assert note.subject == "some subject"
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NotesManager.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()
      assert {:ok, %Note{} = note} = NotesManager.update_note(note, @update_attrs)
      assert note.body == "some updated body"
      assert note.subject == "some updated subject"
    end

    test "update_note/2 with invalid data returns error changeset" do
      note = note_fixture()
      assert {:error, %Ecto.Changeset{}} = NotesManager.update_note(note, @invalid_attrs)
      assert note == NotesManager.get_note!(note.id)
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = NotesManager.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> NotesManager.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = NotesManager.change_note(note)
    end
  end
end
