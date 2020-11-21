defmodule AcariServerWeb.PageController do
  use AcariServerWeb, :controller

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:xterm]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def zabbix(conn = %{assigns: %{current_user: %{is_admin: true}}}, %{
        "sync" => sync_type,
        "redirect_to" => redirect_to
      }) do
    mes =
      case sync_type do
        "full" ->
          AcariServer.Zabbix.ZbxApi.zbx_hosts_sync(update: true)
          "Полная"

        _ ->
          AcariServer.Zabbix.ZbxApi.zbx_hosts_sync()
          "Быстрая"
      end

    conn
    |> put_flash(:info, "#{mes} синхронизация началась.")
    |> redirect(to: redirect_to)
  end

  def zabbix(conn, %{"sync" => _} = params) do
    is_admin(conn, params)
  end

  def zabbix(conn, params) do
    zbx_url =
      case Application.get_env(:acari_server, :zabbix)[:zbx_ext_url] do
        url when is_binary(url) ->
          url

        _ ->
          zbx_web_url = conn |> Plug.Conn.request_url() |> URI.parse()
          zbx_web_port = Application.get_env(:acari_server, :zabbix)[:zbx_web_port] || 10433
          "#{zbx_web_url.scheme}://#{zbx_web_url.host}:#{zbx_web_port}"
      end

    zbx_url =
      case params do
        %{"name" => name} ->
          hostid = AcariServer.Zabbix.ZbxApi.zbx_get_host_id(name)
          zbx_url <> "/host_screen.php?hostid=#{hostid}"

        _ ->
          zbx_url
      end

    redirect(conn, external: zbx_url)
  end

  def xterm(conn, params) do
    render(conn, "xterm.html", err_mes: params["err_mes"])
  end

  def help(conn, _params) do
    render(conn, "help.html")
  end

  def faq(conn, _params) do
    render(conn, "faq.html")
  end

  def chat(conn, _params) do
    render(conn, "chat.html")
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

  def upload(conn, params) do
    {type, mes} =
      with %{path: path, filename: filename} <- params["upload"],
           home when is_binary(home) <- System.user_home(),
           target_dir <- home <> "/uploads/",
           {_, 0} <- System.cmd("mkdir", ["-p", target_dir]),
           :ok <- File.cp(path, target_dir <> filename) do
        {:info, "Файл успешно загружен"}
      else
        res -> {:error, "Ошибка загрузки: #{inspect(res)}"}
      end

    conn
    |> put_flash(type, mes)
    |> redirect(to: Routes.page_path(conn, :xterm))
  end
end
