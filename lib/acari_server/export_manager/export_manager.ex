defmodule AcariServer.ExportManager do
  @moduledoc """
  The ExportManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.ExportManager.Export

  @doc """
  Returns the list of exports.

  ## Examples

      iex> list_exports()
      [%Export{}, ...]

  """
  def list_exports do
    RepoRO.all(Export)
  end

  def list_exports(user) do
    RepoRO.all(Export)
    |> Enum.filter(fn %{user_id: user_id, common: common} -> common or user.id == user_id end)
  end

  @doc """
  Gets a single export.

  Raises `Ecto.NoResultsError` if the Export does not exist.

  ## Examples

      iex> get_export!(123)
      %Export{}

      iex> get_export!(456)
      ** (Ecto.NoResultsError)

  """
  def get_export!(id), do: RepoRO.get!(Export, id)

  def get_export_by(user_id, type, name) do
    Export
    |> Repo.get_by(user_id: user_id, type: type, name: name)
  end

  @doc """
  Creates a export.

  ## Examples

      iex> create_export(%{field: value})
      {:ok, %Export{}}

      iex> create_export(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_export(attrs \\ %{}) do
    %Export{}
    |> Export.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a export.

  ## Examples

      iex> update_export(export, %{field: new_value})
      {:ok, %Export{}}

      iex> update_export(export, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_export(%Export{} = export, attrs) do
    export
    |> Export.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a export.

  ## Examples

      iex> delete_export(export)
      {:ok, %Export{}}

      iex> delete_export(export)
      {:error, %Ecto.Changeset{}}

  """
  def delete_export(%Export{} = export) do
    Repo.delete(export)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking export changes.

  ## Examples

      iex> change_export(export)
      %Ecto.Changeset{data: %Export{}}

  """
  def change_export(%Export{} = export, attrs \\ %{}) do
    Export.changeset(export, attrs)
  end
end
