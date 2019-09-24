defmodule AcariServerWeb.PageController do
  use AcariServerWeb, :controller

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:xterm]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def zabbix(conn, _params) do
    zbx_url =
      case Application.get_env(:acari_server, :zabbix)[:zbx_ext_url] do
        url when is_binary(url) ->
          url

        _ ->
          zbx_web_url = conn |> Plug.Conn.request_url() |> URI.parse()
          zbx_web_port = Application.get_env(:acari_server, :zabbix)[:zbx_web_port] || 10433
          "#{zbx_web_url.scheme}://#{zbx_web_url.host}:#{zbx_web_port}"
      end

    redirect(conn, external: zbx_url)
  end

  def xterm(conn, _params) do
    render(conn, "xterm.html")
  end

  def help(conn, _params) do
    render(conn, "help.html")
  end

  def faq(conn, _params) do
    render(conn, "faq.html")
  end

  def secret(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "secret.html", current_user: user)
  end

  def noauth(conn, %{"message" => mes}) do
    render(conn, "noauth.html", message: mes)
  end

  def test(conn, _params) do
    conn
    |> put_resp_content_type("application/x-sh")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"setup.sh\""
    )
    |> send_resp(200, "echo OK\n")
  end
end
