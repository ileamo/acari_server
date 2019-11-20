defmodule AcariServer.ServerManager do
  @moduledoc """
  The ServerManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.ServerManager.Server
  alias AcariServer.Mnesia

  @doc """
  Returns the list of servers.

  ## Examples

      iex> list_servers()
      [%Server{}, ...]

  """
  def list_servers do
    RepoRO.all(Server)
  end

  @doc """
  Gets a single server.

  Raises `Ecto.NoResultsError` if the Server does not exist.

  ## Examples

      iex> get_server!(123)
      %Server{}

      iex> get_server!(456)
      ** (Ecto.NoResultsError)

  """
  def get_server!(id), do: RepoRO.get_wait(Server, id)

  @doc """
  Creates a server.

  ## Examples

      iex> create_server(%{field: value})
      {:ok, %Server{}}

      iex> create_server(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server(attrs \\ %{}) do
    res =
      %Server{}
      |> Server.changeset(attrs)
      |> Repo.insert()

    Mnesia.update_servers_list(Repo.all(Server))
    res
  end

  @doc """
  Updates a server.

  ## Examples

      iex> update_server(server, %{field: new_value})
      {:ok, %Server{}}

      iex> update_server(server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server(%Server{} = server, attrs) do
    res =
      server
      |> Server.changeset(attrs)
      |> Repo.update()

    Mnesia.update_servers_list(Repo.all(Server))
    res
  end

  @doc """
  Deletes a Server.

  ## Examples

      iex> delete_server(server)
      {:ok, %Server{}}

      iex> delete_server(server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server(%Server{} = server) do
    res = Repo.delete_wait(server)
    Mnesia.update_servers_list(Repo.all(Server))
    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server changes.

  ## Examples

      iex> change_server(server)
      %Ecto.Changeset{source: %Server{}}

  """
  def change_server(%Server{} = server) do
    Server.changeset(server, %{})
  end
end
