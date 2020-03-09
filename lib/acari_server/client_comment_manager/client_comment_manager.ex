defmodule AcariServer.ClientCommentManager do
  @moduledoc """
  The ClientCommentManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.ClientCommentManager.ClientComment

  @doc """
  Returns the list of client_comments.

  ## Examples

      iex> list_client_comments()
      [%ClientComment{}, ...]

  """
  def list_client_comments do
    Repo.all(ClientComment)
  end

  @doc """
  Gets a single client_comment.

  Raises `Ecto.NoResultsError` if the Client comment does not exist.

  ## Examples

      iex> get_client_comment!(123)
      %ClientComment{}

      iex> get_client_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client_comment!(id), do: Repo.get!(ClientComment, id)

  @doc """
  Creates a client_comment.

  ## Examples

      iex> create_client_comment(%{field: value})
      {:ok, %ClientComment{}}

      iex> create_client_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client_comment(attrs \\ %{}) do
    %ClientComment{}
    |> ClientComment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client_comment.

  ## Examples

      iex> update_client_comment(client_comment, %{field: new_value})
      {:ok, %ClientComment{}}

      iex> update_client_comment(client_comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client_comment(%ClientComment{} = client_comment, attrs) do
    client_comment
    |> ClientComment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client_comment.

  ## Examples

      iex> delete_client_comment(client_comment)
      {:ok, %ClientComment{}}

      iex> delete_client_comment(client_comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client_comment(%ClientComment{} = client_comment) do
    Repo.delete(client_comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client_comment changes.

  ## Examples

      iex> change_client_comment(client_comment)
      %Ecto.Changeset{source: %ClientComment{}}

  """
  def change_client_comment(%ClientComment{} = client_comment) do
    ClientComment.changeset(client_comment, %{})
  end

  def parse_comments(comments_list, user_id) do
    case comments_list do
      [_ | _] = comments ->
        {user_comment_list, list} =
          comments
          |> Enum.split_with(fn %{user_id: uid} -> uid == user_id end)

        user_comment =
          case user_comment_list do
            [user_comment] -> user_comment
            _ -> %{comment: "", id: nil}
          end

        list =
          list
          |> Enum.map(fn %{user: %{username: username}, comment: comment, updated_at: tm} ->
            "<h6><strong>#{AcariServer.db_time_to_local(tm)} #{username}:</strong></h6><p>#{
              comment
            }</p>"
          end)
          |> Kernel.++([
            case user_comment.id do
              nil ->
                "<h6><strong>Введите комментарий:</strong></h6>"

              _ ->
                "<h6><strong>#{AcariServer.db_time_to_local(user_comment.updated_at)} #{
                  user_comment.user.username
                }:</strong></h6>"
            end
          ])
          |> Enum.join("<hr/>")

        {true, list, user_comment.comment, user_comment.id}

      _ ->
        {nil, "<h6><strong>Введите комментарий:</strong></h6>", nil, nil}
    end
  end
end
