defmodule AcariServerWeb.Api.BogatkaController do
  use AcariServerWeb, :controller
  alias AcariServer.UserManager.Guardian
  alias AcariServer.AuditManager

  def sign_in(conn, %{"username" => username, "password" => password}) do
    case AcariServer.UserManager.authenticate_user(username, password) do
      {:ok, user = %{api: true}} ->
        {:ok, jwt, _claims} =
          Guardian.encode_and_sign(
            %{
              user: user
            },
            %{},
            ttl: {60, :minute}
          )

        conn
        |> AuditManager.create_audit_log({"auth", username}, "signin")
        |> render("auth.json", %{username: user.username, jwt: jwt})

      _ ->
        conn
        |> AuditManager.create_audit_log({"auth", username}, "signin_err")
        |> render("api_error.json", %{payload: %{message: :invalid_credentials}})
    end
  end

  def sign_out(conn, _params) do
    jwt = Guardian.Plug.current_token(conn)
    Guardian.revoke(jwt)
    render(conn, "api_result.json", %{result: "OK"})
  end

  # Get.clients_list
  def bogatka(conn, %{"method" => "get.clients_list", "params" => %{"group" => group}}) do
    clients_list =
      get_clients_from_group(group)
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

  def bogatka(conn, %{"method" => "get.clients_list"}) do
    render(conn, "api_error.json",
      payload: %{
        message: "Bad params",
        data: "Must be parameter 'group' with group id, name or true for all groups"
      }
    )
  end

  # Get.metric
  def bogatka(
        conn,
        params = %{
          "method" => "get.metrics",
          "params" => %{"metrics" => metric}
        }
      )
      when is_binary(metric) do
    bogatka(conn, params |> put_in(["params", "metrics"], [metric]))
  end

  def bogatka(conn, %{
        "method" => "get.metrics",
        "params" => %{"metrics" => metrics_list} = params
      })
      when is_list(metrics_list) do
    clients_list = get_clients_list(params)
    render(conn, "api_result.json", %{payload: get_metrics(clients_list, metrics_list)})
  end

  def bogatka(
        conn,
        params = %{
          "method" => "get.metrics"
        }
      ) do
    render(conn, "api_error.json", payload: %{message: "Bad params", data: params})
  end

  def bogatka(
        conn,
        %{
          "method" => "get.ai_notes",
          "params" => params
        }
      ) do
    clients_list = get_clients_list(params)
    render(conn, "api_result.json", %{payload: get_ai_notes(clients_list)})
  end

  # default
  def bogatka(conn, params) do
    render(conn, "api_error.json", payload: %{message: "Bad request", data: params})
  end

  # Functions
  defp get_metrics(clients_list, metrics_list) do
    clients_list
    |> Enum.uniq()
    |> Enum.map(fn id ->
      %{
        client: id,
        metrics:
          ((AcariServer.Mnesia.get_tunnel_state(id) || [])
           |> Enum.filter(fn
             {metric_id, %{data: data}} when is_binary(data) ->
               Enum.member?(metrics_list, metric_id)

             _ ->
               false
           end)
           |> Enum.map(fn {id, map} ->
             %{
               name: id,
               data: map[:data] |> try_json(),
               timestamp: map[:timestamp],
               source: "script"
             }
           end)) ++
            (AcariServer.Mnesia.get_zabbix(id)
             |> Enum.filter(fn %{key: key} -> Enum.member?(metrics_list, key) end)
             |> Enum.map(fn %{key: key, value: value, timestamp: timestamp} ->
               %{name: key, data: value |> try_json(), timestamp: timestamp, source: "zabbix"}
             end))
      }
    end)
  end

  defp try_json(str) do
    case Jason.decode(str) do
      {:ok, map} -> map
      _ -> str
    end
  end

  defp get_ai_notes(clients_list) do
    clients_list
    |> Enum.uniq()
    |> Enum.map(fn id ->
      %{
        client: id,
        ai_notes:
          (AcariServer.Mnesia.get_tunnel_state(id)[:wizard] || [])
          |> Enum.map(fn
            {"errormsg[" <> port, %{value: value}} ->
              %{port: String.slice(port, 0..-2), message: value}

            _ ->
              nil
          end)
          |> Enum.reject(&is_nil/1)
      }
    end)
  end

  defp get_clients_list(%{"clients" => client}) when is_binary(client), do: [client]
  defp get_clients_list(%{"clients" => client}) when is_list(client), do: client

  defp get_clients_list(%{"group" => group}) do
    get_clients_from_group(group)
    |> Enum.map(fn %{name: name} -> name end)
  end

  defp get_clients_list(_), do: []

  defp get_clients_from_group(group) do
    case group do
      true ->
        AcariServer.NodeManager.list_nodes()

      _ ->
        case group do
          name when is_binary(name) -> AcariServer.GroupManager.get_group_by_name(name)
          id when is_integer(id) -> AcariServer.GroupManager.get_group_with_nodes(id)
          _ -> nil
        end
        |> case do
          %AcariServer.GroupManager.Group{nodes: client_list} -> client_list
          _ -> []
        end
    end
  end
end
