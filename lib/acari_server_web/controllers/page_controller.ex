defmodule AcariServerWeb.PageController do
  use AcariServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def zabbix(conn, _params) do
    zbx_url = conn |> Plug.Conn.request_url() |> URI.parse()
    zbx_port = Application.get_env(:acari_server, :zabbix)[:web_port] || 10433
    redirect(conn, external: "https://#{zbx_url.host}:#{zbx_port}")
  end

  def secret(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "secret.html", current_user: user)
  end

  def noauth(conn, _) do
    render(conn, "noauth.html")
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
