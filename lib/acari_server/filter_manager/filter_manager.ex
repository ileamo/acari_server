defmodule AcariServer.FilterManager do
  @moduledoc """
  The FilterManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.FilterManager.Filter

  @doc """
  Returns the list of filrers.

  ## Examples

      iex> list_filters()
      [%Filter{}, ...]

  """
  def list_filters() do
    RepoRO.all(Filter)
    |> Repo.preload(:user)
  end

  def list_filters(user) do
    RepoRO.all(Filter)
    |> Enum.filter(fn %{user_id: user_id, common: common} -> common or user.id == user_id end)
  end

  @doc """
  Gets a single filter.

  Raises `Ecto.NoResultsError` if the Filter does not exist.

  ## Examples

      iex> get_filter!(123)
      %Filter{}

      iex> get_filter!(456)
      ** (Ecto.NoResultsError)

  """
  def get_filter!(id) do
    RepoRO.get!(Filter, id)
    |> RepoRO.preload(:user)
  end

  def get_filter_wo_user!(id) do
    RepoRO.get!(Filter, id)
  end

  @doc """
  Creates a filter.

  ## Examples

      iex> create_filter(%{field: value})
      {:ok, %Filter{}}

      iex> create_filter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_filter(attrs \\ %{}) do
    %Filter{}
    |> Filter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a filter.

  ## Examples

      iex> update_filter(filter, %{field: new_value})
      {:ok, %Filter{}}

      iex> update_filter(filter, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_filter(%Filter{} = filter, attrs) do
    filter
    |> Filter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a filter.

  ## Examples

      iex> delete_filter(filter)
      {:ok, %Filter{}}

      iex> delete_filter(filter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_filter(%Filter{} = filter) do
    Repo.delete(filter)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking filter changes.

  ## Examples

      iex> change_filter(filter)
      %Ecto.Changeset{source: %Filter{}}

  """
  def change_filter(%Filter{} = filter) do
    Filter.changeset(filter, %{})
  end
end
