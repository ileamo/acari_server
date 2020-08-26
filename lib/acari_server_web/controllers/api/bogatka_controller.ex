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

  def bogatka(conn, %{"method" => "get.client", "params" => %{"id" => id}}) do
    tun = AcariServer.Mnesia.get_tunnel_state(id)
    #links_state = AcariServer.Mnesia.get_link_list_for_tunnel(id)
    render(conn, "api_result.json", %{payload: tun})

  end

  def bogatka(conn, params) do
    render(conn, "api_error.json", payload: %{message: "bad request", data: params})
  end

end
