defmodule AcariServer.Zabbix.ZbxApi do
  require Logger
  use GenServer

  @zbx_url "http://zabbix-web-nginx-pgsql/api_jsonrpc.php"

  defmodule State do
    defstruct [
      :auth,
      :hosts
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    {:ok, %State{}, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, state) do
    with {:ok, auth} <- zbx_auth(),
         {:ok, [%{"groupid" => hostgroup_id}]} <- get_hostgroup_id(auth),
         {:ok, hosts} <- get_hosts(auth, hostgroup_id),
         hosts <-
           hosts
           |> Enum.map(fn %{"host" => host_name, "hostid" => host_id} ->
             {:ok, items} = get_host_items(auth, host_id)

             items =
               items
               |> Enum.map(fn %{"key_" => key} = item ->
                 nil
                 {key, item}
               end)
               |> Enum.into(%{})

             {host_name, %{hostid: host_id, items: items}}
           end)
           |> Enum.into(%{}) do
      {:noreply, %State{state | auth: auth, hosts: hosts}}
    else
      res ->
        Logger.error("Can't init zbx_api: #{inspect(res)}")
        {:noreply, state}
    end
  end

  defp request(method, params, auth) do
    {:ok, json} =
      Jason.encode(%{
        jsonrpc: "2.0",
        method: method,
        params: params,
        id: 1,
        auth: auth
      })

    json
  end

  def zbx_auth() do
    zbx_post("user.login", %{user: "Admin", password: "zabbix"}, nil)
  end

  def get_hostgroup_id(auth) do
    zbx_post("hostgroup.get", %{output: ["extend"], filter: %{name: ["acari_clients"]}}, auth)
  end

  def get_hosts(auth, hostgroup_id) do
    zbx_post("host.get", %{output: ["host"], groupids: [hostgroup_id]}, auth)
  end

  def get_host_items(auth, host_id) do
    zbx_post("item.get", %{hostids: host_id, output: ["key_", "value_type"]}, auth)
  end

  def zbx_post(method, params, auth) do
    with request <- request(method, params, auth),
         {:ok, %{status_code: 200, body: body_json}} <-
           HTTPoison.post(
             @zbx_url,
             request,
             [
               {"Content-Type", "application/json-rpc"}
             ]
           ),
         {:ok, %{"result" => result}} <- Jason.decode(body_json) do
      {:ok, result}
    else
      {:ok, response} ->
        {:error, {:bad_response, response}}

      {:error, reason} ->
        {:error, reason}

      res ->
        {:error, res}
    end
  end

  defp zabbix_sender(host, key, value) do
    Task.start(fn ->
      case System.cmd("zabbix_sender", [
             "-zzabbix-server-pgsql",
             "-p10051",
             "-s",
             host,
             "-k",
             key,
             "-o",
             to_string(value)
           ]) do
        {res, 0} -> Logger.debug("zabbix_sender: #{res}")
        {err, code} -> Logger.warn("zabbix_sender exits with code #{code}, output: #{err}")
      end
    end)
  end

  @impl true
  def handle_cast({:send, host, key, value}, state) do
    zabbix_sender(host, key, value)
    {:noreply, state}
  end

  # API
  def zbx_send(host, key, value) do
    GenServer.cast(__MODULE__, {:send, host, key, value})
  end

  def zbx_send_master(key, value) do
    zabbix_sender("acari_master", key, value)
  end
end
