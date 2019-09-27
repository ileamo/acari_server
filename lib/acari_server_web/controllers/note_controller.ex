defmodule AcariServerWeb.NoteController do
  use AcariServerWeb, :controller

  alias AcariServer.NoteManager
  alias AcariServer.NoteManager.Note

  def index(conn, _params) do
    notes = NoteManager.list_notes()
    render(conn, "index.html", notes: notes)
  end

  def new(conn, _params) do
    changeset = NoteManager.change_note(%Note{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{current_user: %{id: user_id}}} = conn, %{"note" => note_params}) do
    case NoteManager.create_note(note_params |> Map.put("user_id", user_id)) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "Note created successfully.")
        |> redirect(to: Routes.note_path(conn, :show, note))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    note = NoteManager.get_note!(id)
    render(conn, "show.html", note: note)
  end

  def edit(conn, %{"id" => id}) do
    note = NoteManager.get_note!(id)
    changeset = NoteManager.change_note(note)
    render(conn, "edit.html", note: note, changeset: changeset)
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    note = NoteManager.get_note!(id)

    case NoteManager.update_note(note, note_params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "Note updated successfully.")
        |> redirect(to: Routes.note_path(conn, :show, note))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", note: note, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    note = NoteManager.get_note!(id)
    {:ok, _note} = NoteManager.delete_note(note)

    conn
    |> put_flash(:info, "Note deleted successfully.")
    |> redirect(to: Routes.note_path(conn, :index))
  end
end
