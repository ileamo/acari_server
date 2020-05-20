defmodule AcariServer.SysConfigManager do
  @moduledoc """
  The SysConfigManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.SysConfigManager.SysConfig

  @doc """
  Returns the list of sysconfigs.

  ## Examples

      iex> list_sysconfigs()
      [%SysConfig{}, ...]

  """
  def list_sysconfigs do
    Repo.all(SysConfig)
  end

  @doc """
  Gets a single sys_config.

  Raises `Ecto.NoResultsError` if the Sys config does not exist.

  ## Examples

      iex> get_sys_config!(123)
      %SysConfig{}

      iex> get_sys_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sys_config!(id), do: Repo.get!(SysConfig, id)

  @doc """
  Creates a sys_config.

  ## Examples

      iex> create_sys_config(%{field: value})
      {:ok, %SysConfig{}}

      iex> create_sys_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sys_config(attrs \\ %{}) do
    %SysConfig{}
    |> SysConfig.changeset(attrs)
    |> Repo.insert()
  end

  def insert_or_update_sys_config(attrs = %{key: key}) do
    case SysConfig |> Repo.get_by(key: key) do
      nil -> %SysConfig{}
      config -> config
    end
    |> SysConfig.changeset(attrs)
    |> Repo.insert_or_update()
  end



  @doc """
  Updates a sys_config.

  ## Examples

      iex> update_sys_config(sys_config, %{field: new_value})
      {:ok, %SysConfig{}}

      iex> update_sys_config(sys_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sys_config(%SysConfig{} = sys_config, attrs) do
    sys_config
    |> SysConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sys_config.

  ## Examples

      iex> delete_sys_config(sys_config)
      {:ok, %SysConfig{}}

      iex> delete_sys_config(sys_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sys_config(%SysConfig{} = sys_config) do
    Repo.delete(sys_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sys_config changes.

  ## Examples

      iex> change_sys_config(sys_config)
      %Ecto.Changeset{data: %SysConfig{}}

  """
  def change_sys_config(%SysConfig{} = sys_config, attrs \\ %{}) do
    SysConfig.changeset(sys_config, attrs)
  end
end
