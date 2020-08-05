defmodule AcariServer.ScriptManager do
  @moduledoc """
  The ScriptManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.ScriptManager.Script

  @doc """
  Returns the list of scripts.

  ## Examples

      iex> list_scripts()
      [%Script{}, ...]

  """
  def list_scripts do
    Script
    |> RepoRO.all()
    |> RepoRO.preload(:templates)
  end

  def script_name_id_pairs_list(no_script) do
    list_scripts()
    |> Enum.map(fn %{name: name, id: id} -> {name, id} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> List.insert_at(0, {no_script, nil})
  end

  @doc """
  Gets a single script.

  Raises `Ecto.NoResultsError` if the Script does not exist.

  ## Examples

      iex> get_script!(123)
      %Script{}

      iex> get_script!(456)
      ** (Ecto.NoResultsError)

  """
  def get_script!(id) do
    Script
    |> RepoRO.get_wait(id)
    |> RepoRO.preload(:local)
    |> RepoRO.preload(:remote)
    |> RepoRO.preload(:templates)
    |> RepoRO.preload(:terminals)
  end

  def get_script(id) do
    Script
    |> RepoRO.get(id)
  end

  @doc """
  Creates a script.

  ## Examples

      iex> create_script(%{field: value})
      {:ok, %Script{}}

      iex> create_script(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_script(attrs \\ %{}) do
    %Script{}
    |> Script.changeset(attrs)
    |> Script.put_templates(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a script.

  ## Examples

      iex> update_script(script, %{field: new_value})
      {:ok, %Script{}}

      iex> update_script(script, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_script(%Script{} = script, attrs) do
    script
    |> Script.changeset(attrs)
    |> Script.put_templates(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Script.

  ## Examples

      iex> delete_script(script)
      {:ok, %Script{}}

      iex> delete_script(script)
      {:error, %Ecto.Changeset{}}

  """
  def delete_script(%Script{} = script) do
    res = Repo.delete_wait(script)
    AcariServer.Scheduler.Api.update_script_jobs()
    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking script changes.

  ## Examples

      iex> change_script(script)
      %Ecto.Changeset{source: %Script{}}

  """
  def change_script(%Script{} = script) do
    Script.changeset(script, %{})
  end

  def get_clients_of_class(%Script{} = script) do
    RepoRO.preload(script, :nodes).nodes
  end
end
