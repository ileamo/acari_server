defmodule AcariServerWeb.Api.AutoconfController do
  use AcariServerWeb, :controller
  alias AcariServer.SFX

  action_fallback(AcariWeb.FallbackController)

  plug :validate_params
  plug :get_res

  defp validate_params(
         conn = %{
           params: %{
             "method" => _method,
             "params" => %{}
           }
         },
         _
       ) do
    conn
  end

  defp validate_params(conn, _) do
    conn
    |> render_and_log_error("No method or params field")
    |> halt()
  end

  defp get_res(
         conn = %{
           params: %{
             "method" => "get.conf",
             "params" => %{"id" => node_name} = params
           }
         },
         _
       ) do
    case AcariServer.NodeManager.get_node_with_script(node_name) do
      %{} = node ->
        conn
        |> assign(:sfx, SFX.create_sfx(:remote, node, params))

      _ ->
        conn
        |> add_discovery(node_name)
        |> render_and_log_error("No configuration for #{node_name}")
        |> halt()
    end
  end

  defp get_res(conn = %{params: %{"method" => "get.conf"}}, _) do
    conn
    |> render_and_log_error("No device id in request params")
    |> halt()
  end

  defp get_res(conn, _) do
    conn
    |> render_and_log_error("Unknown method")
    |> halt()
  end

  @doc """
       For testing use curl:


       curl -H "Content-Type: application/json" -X POST -d '{"method":"get.conf","params":{"id":"NSG1700_1812000001"}}' https://localhost:4001/api -sko setup.sh

       or

       wget --header "Content-Type: application/json"  --post-data '{"method":"get.conf","params":{"id":"NSG1700_1812000001"}}' --no-check-certificate https://localhost:4001/api -qO setup.sh

  """

  def index(conn = %{assigns: %{sfx: conf}}, _) do
    request_log(conn, "OK")
    send_sh_file(conn, conf)
    # render(conn, "result.json", %{id: id, result: %{sfx: conf}})
  end

  def index(conn, _) do
    render_and_log_error(conn, "No configuration")
  end

  defp send_sh_file(conn, content) do
    conn
    |> put_resp_content_type("application/x-sh")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"setup.sh\""
    )
    |> send_resp(200, content)
  end

  defp render_and_log_error(conn, mes) do
    request_log(conn, "ERR: #{mes}")
    send_sh_file(conn, SFX.create_setup(mes))

    # render(conn, "error.json", %{id: id, error: mes})
  end

  #  defp request_log(%{remote_ip: ip, params: %{"params" => params}}, mes) do
  #    RequestLog.create_request(%{
  #      from: ip |> :inet.ntoa() |> to_string(),
  #      request: params,
  #      response: mes
  #    })
  #  end

  defp request_log(_, _) do
  end

  defp add_discovery(
         conn = %{
           remote_ip: ip,
           params: %{
             "params" => node_params
           }
         },
         node_name
       ) do
    AcariServer.NewNodeDiscovery.insert_or_update_new_node(%{
      name: node_name,
      ip_addr: ip |> :inet.ntoa() |> to_string(),
      params: node_params,
      source: "POST"
    })

    conn
  end
end
