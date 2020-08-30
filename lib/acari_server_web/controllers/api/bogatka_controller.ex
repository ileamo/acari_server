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
          "params" => %{"clients" => client}
        }
      )
      when is_binary(client) do
    bogatka(conn, params |> put_in(["params", "clients"], [client]))
  end

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
        "params" => %{"clients" => clients_list, "metrics" => metrics_list}
      })
      when is_list(clients_list) and is_list(metrics_list) do
    render(conn, "api_result.json", %{payload: get_metrics(clients_list, metrics_list)})
  end

  def bogatka(conn, %{
        "method" => "get.metrics",
        "params" => %{"group" => group, "metrics" => metrics_list}
      })
      when is_list(metrics_list) do
    clients_list =
      get_clients_from_group(group)
      |> Enum.map(fn %{name: name} -> name end)

    render(conn, "api_result.json", %{payload: get_metrics(clients_list, metrics_list)})
  end

  def bogatka(
        conn,
        params = %{
          "method" => "get.metrics"
        }
      ) do
    IO.inspect(params)
    render(conn, "api_error.json", payload: %{message: "Bad params", data: params})
  end

  # default
  def bogatka(conn, params) do
    IO.inspect(params)
    render(conn, "api_error.json", payload: %{message: "Bad request", data: params})
  end

  # Functions
  def get_metrics(clients_list, metrics_list) do
    clients_list
    |> Enum.uniq()
    |> Enum.map(fn id ->
      %{
        client: id,
        metrics:
          ((AcariServer.Mnesia.get_tunnel_state(id) || [])
           |> Enum.filter(fn {metric_id, _} -> Enum.member?(metrics_list, metric_id) end)
           |> Enum.map(fn {id, map} ->
             %{name: id, data: map[:data], timestamp: map[:timestamp], source: "script"}
           end)) ++
            (AcariServer.Mnesia.get_zabbix(id)
             |> Enum.filter(fn %{key: key} -> Enum.member?(metrics_list, key) end)
             |> Enum.map(fn %{key: key, value: value, timestamp: timestamp} ->
               %{name: key, data: value, timestamp: timestamp, source: "zabbix"}
             end))
      }
    end)
  end

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
