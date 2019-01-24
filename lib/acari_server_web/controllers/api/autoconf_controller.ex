defmodule AcariServerWeb.Api.AutoconfController do
  use AcariServerWeb, :controller

  action_fallback(AcariWeb.FallbackController)

  plug :validate_params
  plug :get_res

  defp validate_params(
         conn = %{
           params: %{
             "id" => _id,
             "method" => _method,
             "params" => %{}
           }
         },
         _
       ) do
    conn
  end

  defp validate_params(conn = %{params: %{"id" => id}}, _) do
    conn
    |> render_and_log_error(id, "No method or params field")
    |> halt()
  end

  defp validate_params(conn, _) do
    conn
    |> render_and_log_error(0, "No request id")
    |> halt()
  end

  defp get_res(
         conn = %{
           params: %{
             "id" => id,
             "method" => "get.conf",
             "params" => %{"id" => node_name}
           }
         },
         _
       ) do
    case AcariServer.NodeManager.get_node_with_script(node_name) do
      %{} = _node ->
        conn
        |> assign(:configuration, "# Содержимое саморазархивируещегося скрипта")

      _ ->
        conn
        |> add_discovery(node_name)
        |> render_and_log_error(id, "no configuration for #{node_name}")
        |> halt()
    end
  end

  defp get_res(conn = %{params: %{"id" => id, "method" => "get.conf"}}, _) do
    conn
    |> render_and_log_error(id, "No device id")
    |> halt()
  end

  defp get_res(conn = %{params: %{"id" => id}}, _) do
    conn
    |> render_and_log_error(id, "Unknown method")
    |> halt()
  end

  @doc """
       For testing use curl:

       curl -H "Content-Type: application/json" -X POST -d '{"id":1,"method":"get.conf","params":{"id":"NSG1700_1812000001"}}' http://localhost:4000/api

  """

  def index(conn = %{assigns: %{configuration: conf}}, _) do
    request_log(conn, "OK")
    send_sh_file(conn, conf)
    # render(conn, "result.json", %{id: id, result: %{configuration: conf}})
  end

  def index(conn = %{params: %{"id" => id}}, _) do
    render_and_log_error(conn, id, "No configuration")
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

  defp render_and_log_error(conn, _id, mes) do
    request_log(conn, "ERR: #{mes}")
    send_sh_file(conn, "echo #{inspect(mes)}")

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
      params: node_params
    })

    conn
  end
end
