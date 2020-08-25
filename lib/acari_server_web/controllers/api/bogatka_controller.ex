defmodule AcariServerWeb.Api.BogatkaController do
  use AcariServerWeb, :controller
  alias AcariServer.UserManager.Guardian

  def bogatka(conn, params) do
    IO.inspect(params)
    render(conn, "client.json")
  end

  def sign_in(conn, %{"username" => username, "password" => password}) do
    case AcariServer.UserManager.authenticate_user(username, password) do
      {:ok, user} ->
        {:ok, jwt, claims} =
          Guardian.encode_and_sign(
            %{
              user: user
            },
            %{},
            ttl: {60, :minute}
          )

        render(conn, "auth.json", %{username: user.username, jwt: jwt})

      {:error, reason} ->
        render(conn, "api_error.json", %{reason: reason})
    end
  end

  def sign_out(conn, _params) do
    jwt = Guardian.Plug.current_token(conn)
    Guardian.revoke(jwt)
    render(conn, "api_result.json", %{result: "OK"})
  end
end
