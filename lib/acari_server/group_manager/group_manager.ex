defmodule AcariServer.GroupManager do
  @moduledoc """
  The GroupManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.GroupManager.Group
  alias AcariServer.Zabbix.ZbxApi

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    RepoRO.all(Group)
  end

  def list_groups(user) do
    case user.is_admin do
      true ->
        RepoRO.all(Group)

      _ ->
        user
        |> AcariServer.RepoRO.preload(:groups)
        |> Map.get(:groups)
    end
  end

  def group_name_id_pairs_list() do
    list_groups()
    |> Enum.map(fn %{name: name, id: id} -> {name, id} end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  def group_name_id_pairs_list(all) do
    group_name_id_pairs_list()
    |> List.insert_at(0, {all, nil})
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id) do
    Group
    |> RepoRO.get_wait(id)
    |> RepoRO.preload(:nodes)
    |> RepoRO.preload(:users)
  end

  def get_group_with_nodes(id) do
    Group
    |> RepoRO.get(id)
    |> RepoRO.preload(:nodes)
  end

  def get_group_wo_nodes!(id) do
    Group
    |> RepoRO.get!(id)
  end

  def get_group_by_name(name) do
    Group
    |> RepoRO.get_by(name: name)
    |> RepoRO.preload(:nodes)
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    res =
      %Group{}
      |> Group.changeset(attrs)
      |> Repo.insert()

    Task.start(fn ->
      Process.sleep(1_000)
      ZbxApi.zbx_groups_sync()
    end)

    res
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    res = Repo.delete_wait(group)
    ZbxApi.zbx_groups_sync()
    AcariServer.Scheduler.Api.update_script_jobs()

    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group changes.

  ## Examples

      iex> change_group(group)
      %Ecto.Changeset{source: %Group{}}

  """
  def change_group(%Group{} = group) do
    Group.changeset(group, %{})
  end

  def groups_list(obj) do
    obj.groups
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(", ")
  end

  def group_id_list(nil) do
    []
  end

  def group_id_list(obj) do
    obj.groups
    |> Enum.map(fn %{id: id} -> id end)
  end
end
