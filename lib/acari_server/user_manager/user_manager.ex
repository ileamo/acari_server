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

  def get_user!(id) do
    User
    |> RepoRO.get_wait(id)
    |> RepoRO.preload(groups_users: [:group])
  end

  def get_user!(id, :clean) do
    RepoRO.get!(User, id)
  end

  def get_user!(id, :rw) do
    User
    |> Repo.get(id)
    |> Repo.preload(groups_users: [:group])
  end

  def get_user(id) do

    RepoRO.get(User, id)
    |> RepoRO.preload(:groups_users)
  end

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


  def authenticate_user(username, plain_text_password) do
    query = from u in User, where: u.username == ^username

    case RepoRO.one(query) do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      %{password_hash: nil} ->
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(plain_text_password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def load_current_user(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    case user do
      %AcariServer.UserManager.User{} = user ->
        token = Phoenix.Token.sign(conn, "user token", user.id)

        conn
        |> Conn.assign(:current_user, user)
        |> Conn.assign(:user_token, token)

      _ ->
        conn
    end
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

  def get_user_node_rights(user_id, node_id) do
    group_list = AcariServer.GroupNodeAssociation.get_group_list_for_node(node_id)

    case user_id do
      user = %AcariServer.UserManager.User{} -> user.groups_users
      id -> AcariServer.GroupUserAssociation.get_user(id)
    end
    |> Enum.filter(fn %{group_id: group_id} -> Enum.member?(group_list, group_id) end)
    |> Enum.map(fn %{rights: rights} -> rights end)
    |> Enum.reduce_while(nil, fn
      "rw", _ -> {:halt, "rw"}
      "ro", _ -> {:cont, "ro"}
      _, acc -> {:cont, acc}
    end)
  end

  # read_only and read_write test
  def is_user_node_ro(conn = %{assigns: %{current_user: %{is_admin: true}}}, _opts) do
    conn
  end

  def is_user_node_ro(
        conn = %{assigns: %{current_user: %{id: user_id}}, params: %{"id" => node_id}},
        :node
      ) do
    case get_user_node_rights(user_id, String.to_integer(node_id)) do
      "rw" -> conn
      "ro" -> conn
      _ -> no_auth(conn, "Вы не являетесь членом группы")
    end
  end

  def is_user_node_ro(conn, _opts) do
    no_auth(conn, "Проблемы с правами")
  end

  # read_write test
  def is_user_node_rw(conn = %{assigns: %{current_user: %{is_admin: true}}}, _opts) do
    conn
  end

  def is_user_node_rw(
        conn = %{assigns: %{current_user: %{id: user_id}}, params: %{"id" => node_id}},
        :node
      ) do
    case get_user_node_rights(user_id, String.to_integer(node_id)) do
      "rw" -> conn
      "ro" -> no_auth(conn, "У Вас права только для просмотра этого клиента")
      _ -> no_auth(conn, "Вы не являетесь членом группы")
    end
  end

  def is_user_node_rw(conn, _opts) do
    no_auth(conn, "Проблемы с правами")
  end

  def get_disabled(%{is_admin: true}, _), do: ""

  def get_disabled(current_user, node_id) do
    case AcariServer.UserManager.get_user_node_rights(current_user, node_id) do
      "rw" -> ""
      _ -> "bg-disabled"
    end
  end

  def get_disabled(current_user) do
    (current_user.is_admin && "") || "bg-disabled"
  end

  def get_rights_text_color(%{is_admin: true}, _), do: ""

  def get_rights_text_color(current_user, node_id) do
    case AcariServer.UserManager.get_user_node_rights(current_user, node_id) do
      "rw" -> "text-success"
      "no" -> "text-danger"
      _ -> ""
    end
  end

  def is_script_executable_for_user?(template_rights, user_rights) do
    case user_rights do
      "admin" ->
        :ok

      "rw" ->
        case template_rights do
          "admin" -> :no_rights
          _ -> :ok
        end

      "ro" ->
        case template_rights do
          "ro" -> :ok
          _ -> :no_rights
        end
    end
  end

  def get_node_id_list_for_user(user) do
    user =
      case user do
        %AcariServer.UserManager.User{} -> user
        _ -> AcariServer.UserManager.get_user!(user, :clean)
      end

    case user.is_admin do
      true ->
        nil

      _ ->
        AcariServer.GroupUserAssociation.get_user(user.id)
        |> Enum.map(fn %{group_id: group_id} ->
          AcariServer.GroupNodeAssociation.get_node_list_for_group(group_id)
        end)
        |> List.flatten()
        |> Enum.uniq()
    end
  end
end
