defmodule AcariServerWeb.Api.BogatkaController do
  use AcariServerWeb, :controller
  alias AcariServer.UserManager.Guardian

  def sign_in(conn, %{"username" => username, "password" => password}) do
    case AcariServer.UserManager.authenticate_user(username, password) do
      {:ok, user} ->
        {:ok, jwt, _claims} =
          Guardian.encode_and_sign(
            %{
              user: user
            },
            %{},
            ttl: {60 * 24 * 365, :minute}
          )

        render(conn, "auth.json", %{username: user.username, jwt: jwt})

      {:error, reason} ->
        render(conn, "api_error.json", %{payload: %{message: reason}})
    end
  end

  def sign_out(conn, _params) do
    jwt = Guardian.Plug.current_token(conn)
    Guardian.revoke(jwt)
    render(conn, "api_result.json", %{result: "OK"})
  end

  def bogatka(conn, %{"method" => "get.clients_list", "params" => %{"group" => name}}) do
    case AcariServer.GroupManager.get_group_by_name(name) do
      group = %AcariServer.GroupManager.Group{} ->
        clients_list =
          group
          |> Map.get(:nodes)
          |> Enum.map(fn client ->
            %{
              name: client.name,
              description: client.description,
              address: client.address,
              lock: client.lock
            }
          end)

        render(conn, "api_result.json", %{payload: %{clients_list: clients_list, group: name}})

      _ ->
        render(conn, "api_error.json", payload: %{message: "no such group", data: name})
    end
  end

  def bogatka(conn, %{"method" => "get.clients_list"}) do
    clients_list =
      AcariServer.NodeManager.list_nodes()
      |> Enum.map(fn client ->
        %{
          name: client.name,
          description: client.description,
          address: client.address,
          lock: client.lock
        }
      end)

    render(conn, "api_result.json", %{payload: %{clients_list: clients_list}})
  end

  def bogatka(conn, %{"method" => "get.client", "params" => %{"id" => id}}) do
    tun = AcariServer.Mnesia.get_tunnel_state(id)
    # links_state = AcariServer.Mnesia.get_link_list_for_tunnel(id)
    render(conn, "api_result.json", %{payload: tun})
  end

  def bogatka(conn, params) do
    render(conn, "api_error.json", payload: %{message: "bad request", data: params})
  end
end
