defmodule AcariServer.NewNodeDiscovery do
  @moduledoc """
  The NewNodeDiscovery context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.NewNodeDiscovery.NewNode

  @doc """
  Returns the list of newnodes.

  ## Examples

      iex> list_newnodes()
      [%NewNode{}, ...]

  """
  def list_newnodes do
    RepoRO.all(NewNode)
  end

  @doc """
  Gets a single new_node.

  Raises `Ecto.NoResultsError` if the New node does not exist.

  ## Examples

      iex> get_new_node!(123)
      %NewNode{}

      iex> get_new_node!(456)
      ** (Ecto.NoResultsError)

  """
  def get_new_node!(id), do: RepoRO.get!(NewNode, id)

  @doc """
  Creates a new_node.

  ## Examples

      iex> create_new_node(%{field: value})
      {:ok, %NewNode{}}

      iex> create_new_node(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_new_node(attrs \\ %{}) do
    %NewNode{}
    |> NewNode.changeset(attrs)
    |> Repo.insert()
  end

  def insert_or_update_new_node(attrs = %{name: name}) do
    case NewNode |> RepoRO.get_by(name: name) do
      nil -> %NewNode{}
      newnode -> newnode
    end
    |> NewNode.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Updates a new_node.

  ## Examples

      iex> update_new_node(new_node, %{field: new_value})
      {:ok, %NewNode{}}

      iex> update_new_node(new_node, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_new_node(%NewNode{} = new_node, attrs) do
    new_node
    |> NewNode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a NewNode.

  ## Examples

      iex> delete_new_node(new_node)
      {:ok, %NewNode{}}

      iex> delete_new_node(new_node)
      {:error, %Ecto.Changeset{}}

  """
  def delete_new_node(%NewNode{} = new_node) do
    Repo.delete_wait(new_node)
  end

  def delete_new_node_by_name(name) do
    case NewNode |> Repo.get_by(name: name) do
      nil -> nil
      newnode -> Repo.delete(newnode)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking new_node changes.

  ## Examples

      iex> change_new_node(new_node)
      %Ecto.Changeset{source: %NewNode{}}

  """
  def change_new_node(%NewNode{} = new_node) do
    NewNode.changeset(new_node, %{})
  end
end
