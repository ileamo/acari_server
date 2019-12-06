defmodule AcariServer.NodeManager do
  @moduledoc """
  The NodeManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO
  alias AcariServer.NodeManager.Node
  alias AcariServer.Zabbix.ZbxApi

  @doc """
  Returns the list of nodes.

  ## Examples

      iex> list_nodes()
      [%Node{}, ...]

  """
  def list_nodes() do
    Node
    |> RepoRO.all()
    |> RepoRO.preload(:groups)
    |> RepoRO.preload(:script)
  end

  def list_nodes(user) do
    user =
      case user do
        %AcariServer.UserManager.User{} -> user
        _ -> AcariServer.UserManager.get_user!(user, :clean)
      end

    case user.is_admin do
      true ->
        list_nodes()

      _ ->
        user
        |> AcariServer.RepoRO.preload(groups: :nodes)
        |> Map.get(:groups)
        |> Enum.map(fn %{nodes: nodes} -> nodes end)
        |> List.flatten()
        |> Enum.uniq_by(fn %{id: id} -> id end)
    end
  end

  def list_nodes_wo_preload() do
    Node
    |> RepoRO.all()
  end

  @doc """
  Gets a single node.

  Raises `Ecto.NoResultsError` if the Node does not exist.

  ## Examples

      iex> get_node!(123)
      %Node{}

      iex> get_node!(456)
      ** (Ecto.NoResultsError)

  """
  def get_node!(id) do
    Node
    |> RepoRO.get_wait(id)
    |> RepoRO.preload(:groups)
    |> RepoRO.preload(:script)
  end

  def get_node_rw!(id) do
    Node
    |> Repo.get!(id)
  end

  def get_node_by_name(name) do
    Node
    |> RepoRO.get_by(name: name)
  end

  def get_node_with_groups(name) do
    Node
    |> RepoRO.get_by(name: name)
    |> RepoRO.preload(:groups)
  end

  def get_node_with_class(name, script_assoc \\ []) do
    Node
    |> RepoRO.get_by(name: name)
    |> RepoRO.preload(script: script_assoc)
  end

  @doc """
  Creates a node.

  ## Examples

      iex> create_node(%{field: value})
      {:ok, %Node{}}

      iex> create_node(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node(attrs \\ %{}) do
    res =
      %Node{}
      |> Node.changeset(attrs)
      |> AcariServer.GroupManager.Group.put_groups(attrs)
      |> Repo.insert()

    case res do
      {:ok, node = %AcariServer.NodeManager.Node{}} ->
        ZbxApi.zbx_add_host(node)
        res

      _ ->
        res
    end
  end

  @doc """
  Updates a node.

  ## Examples

      iex> update_node(node, %{field: new_value})
      {:ok, %Node{}}

      iex> update_node(node, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_node(%Node{} = node, attrs) do
    res = node
    |> Node.changeset(attrs)
    |> AcariServer.GroupManager.Group.put_groups(attrs)
    |> Repo.update()

    case res do
      {:ok, updated_node = %AcariServer.NodeManager.Node{}} ->
        ZbxApi.zbx_update_host(updated_node, node.name)
        res

      _ ->
        res
    end
  end

  @doc """
  Deletes a Node.

  ## Examples

      iex> delete_node(node)
      {:ok, %Node{}}

      iex> delete_node(node)
      {:error, %Ecto.Changeset{}}

  """
  def delete_node(%Node{} = node) do
    res = Repo.delete_wait(node)
    ZbxApi.zbx_del_host(node.name)
    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking node changes.

  ## Examples

      iex> change_node(node)
      %Ecto.Changeset{source: %Node{}}

  """
  def change_node(%Node{} = node) do
    Node.changeset(node, %{})
  end
end
