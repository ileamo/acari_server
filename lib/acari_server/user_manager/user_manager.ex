defmodule AcariServer.UserManager do
  @moduledoc """
  The UserManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.UserManager.User
  alias Plug.Conn

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    User
    |> Repo.all()
    |> Repo.preload(:groups)
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
    |> Repo.get!(id)
    |> Repo.preload(:groups)
  end

  def get_user(id), do: Repo.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> AcariServer.GroupManager.Group.put_groups(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> AcariServer.GroupManager.Group.put_groups(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
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

    case Repo.one(query) do
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

  def is_user_in_group(
        %{assigns: %{current_user: user}, params: %{"name" => node_name}} = conn,
        _opts
      ) do
    node_groups =
      node_name
      |> AcariServer.NodeManager.get_node_with_groups()
      |> AcariServer.GroupManager.group_id_list()

    user_groups = user |> Repo.preload(:groups) |> AcariServer.GroupManager.group_id_list()

    case node_groups |> Enum.any?(fn x -> Enum.member?(user_groups, x) end) do
      true -> conn
      _ -> no_auth(conn, "Вы не являетесь членом группы")
    end
  end

  def is_user_in_group(conn, _opts) do
    no_auth(conn, "Проблемы с группой")
  end

  defp no_auth(conn, mes) do
    conn
    |> Phoenix.Controller.redirect(
      to: AcariServerWeb.Router.Helpers.page_path(conn, :noauth, message: mes)
    )
    |> Conn.halt()
  end
end
