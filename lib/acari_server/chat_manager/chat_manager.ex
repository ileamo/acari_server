defmodule AcariServer.ChatManager do
  @moduledoc """
  The ChatManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.ChatManager.Chat

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%Chat{}, ...]

  """
  def list_chat_messages do
    RepoRO.all(Chat)
  end


  def get_chat_messages(ndt \\ nil, id \\ nil) do
    case ndt do
      %NaiveDateTime{} = ndt -> Chat |> where([c], c.inserted_at >= ^ndt and c.id != ^id)
      _ -> Chat
    end
    |> order_by(desc: :inserted_at, desc: :id)
    |> limit(20)
    |> RepoRO.all()
    |> Enum.reverse()
    |> RepoRO.preload(:user)
  end

  def get_chat!(id), do: RepoRO.get!(Chat, id)

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat(attrs \\ %{}) do
    %Chat{}
    |> Chat.changeset(attrs)
    |> Repo.insert()
  end

  def delete_chat(%Chat{} = chat) do
    Repo.delete(chat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.

  ## Examples

      iex> change_chat(chat)
      %Ecto.Changeset{source: %Chat{}}

  """
  def change_chat(%Chat{} = chat) do
    Chat.changeset(chat, %{})
  end
end
