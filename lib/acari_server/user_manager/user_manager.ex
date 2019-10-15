defmodule AcariServer.UserManager do
  @moduledoc """
  The UserManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.UserManager.User
  alias Plug.Conn

  alias AcariServer.GroupUserAssociation

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    User
    |> RepoRO.all()
    |> RepoRO.preload(:groups)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    User
    |> RepoRO.get_wait(id)
    #|> RepoRO.preload(:groups)
    |> RepoRO.preload(groups_users: [:group])
  end

  def get_user(id), do: RepoRO.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}, rights) do
    res =
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()

    case res do
      {:ok, user} ->
        update_group_user_assoc(user.id, rights)

      _ ->
        nil
    end

    res
  end

  def update_user(%User{} = user, attrs, rights) do
    res =
      user
      |> User.changeset(attrs)
      |> Repo.update()

    case res do
      {:ok, _} ->
        update_group_user_assoc(user.id, rights)

      _ ->
        nil
    end

    res
  end

  defp update_group_user_assoc(user_id, rights) do
    GroupUserAssociation.delete_user(user_id)

    rights
    |> Enum.each(fn
      {_, "no"} ->
        nil

      {group_id, rights} ->
        GroupUserAssociation.create_group_user(%{
          user_id: user_id,
          group_id: group_id,
          rights: rights
        })
    end)
  end

  def delete_user(%User{} = user) do
    Repo.delete_wait(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  alias Comeonin.Bcrypt

  def authenticate_user(username, plain_text_password) do
    query = from u in User, where: u.username == ^username

    case RepoRO.one(query) do
      nil ->
        Bcrypt.dummy_checkpw()
        {:error, :invalid_credentials}

      %{password_hash: nil} ->
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.checkpw(plain_text_password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def load_current_user(conn, _) do
    conn
    |> Conn.assign(:current_user, Guardian.Plug.current_resource(conn))
  end

  def is_admin(conn = %{assigns: %{current_user: %{is_admin: true}}}, _opts) do
    conn
  end

  def is_admin(conn, _opts) do
    no_auth(conn, "У вас нет прав администратора")
  end

  def is_user_in_group(conn = %{assigns: %{current_user: %{is_admin: true}}}, _opts) do
    conn
  end

  def is_user_in_group(
        %{assigns: %{current_user: user}, params: %{"id" => group_id}} = conn,
        _opts
      ) do
    is_user_in_group(conn, user, [group_id |> String.to_integer()])
  end

  def is_user_in_group(
        %{assigns: %{current_user: user}, params: %{"name" => node_name}} = conn,
        _opts
      ) do
    node_groups =
      node_name
      |> AcariServer.NodeManager.get_node_with_groups()
      |> AcariServer.GroupManager.group_id_list()

    is_user_in_group(conn, user, node_groups)
  end

  def is_user_in_group(conn, _opts) do
    no_auth(conn, "Проблемы с группой")
  end

  defp is_user_in_group(conn, user, groups_list) do
    user_groups = user |> RepoRO.preload(:groups) |> AcariServer.GroupManager.group_id_list()

    case groups_list |> Enum.any?(fn x -> Enum.member?(user_groups, x) end) do
      true -> conn
      _ -> no_auth(conn, "Вы не являетесь членом группы")
    end
  end

  defp no_auth(conn, mes) do
    conn
    |> Phoenix.Controller.redirect(
      to: AcariServerWeb.Router.Helpers.page_path(conn, :noauth, message: mes)
    )
    |> Conn.halt()
  end
end
