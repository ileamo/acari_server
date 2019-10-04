defmodule AcariServer.Zabbix.ZbxApi do
  require Logger
  use GenServer

  defmodule State do
    defstruct [
      :zbx_api_url,
      :zbx_snd_host,
      :zbx_snd_port,
      :zbx_username,
      :zbx_password,
      :auth,
      :hostgroup_id,
      :template_id,
      hosts: %{}
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    case Application.get_env(:acari_server, :zabbix)[:zbx_api_url] do
      url when is_binary(url) ->
        zbx_snd_host = Application.get_env(:acari_server, :zabbix)[:zbx_snd_host] || "localhost"
        zbx_snd_port = Application.get_env(:acari_server, :zabbix)[:zbx_snd_port] || 10051
        zbx_username = Application.get_env(:acari_server, :zabbix)[:zbx_username] || "Admin"

        zbx_password =
          Application.get_env(:acari_server, :zabbix)[:zbx_password] || "acari&zabbix"

        {:ok,
         %State{
           zbx_api_url: url <> "/api_jsonrpc.php",
           zbx_snd_host: zbx_snd_host,
           zbx_snd_port: zbx_snd_port,
           zbx_username: zbx_username,
           zbx_password: zbx_password
         }, {:continue, :init}}

      _ ->
        Logger.warn("Zabbix: No URL for zabbix server")
        :ignore
    end
  end

  @impl true
  def handle_continue(:init, state) do
    with {:ok, auth} <- zbx_auth(state),
         state <- %State{state | auth: auth},
         {:ok, [%{"groupid" => hostgroup_id}]} <- get_hostgroup_id(state),
         {:ok, [%{"templateid" => template_id}]} <- get_template_id(state),
         {:ok, hosts} <- get_hosts(state, hostgroup_id),
         hosts <-
           hosts
           |> Enum.map(fn %{"host" => host_name, "hostid" => host_id} ->
             {:ok, items} = get_host_items(state, host_id)

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
      {:noreply,
       %State{
         state
         | auth: auth,
           hostgroup_id: hostgroup_id,
           template_id: template_id,
           hosts: hosts
       }}
    else
      res ->
        Logger.error("Can't init zbx_api(#{state.zbx_api_url}): #{inspect(res)}")
        Process.sleep(60_000)
        {:stop, :shutdown, state}
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

  def zbx_auth(state) do
    zbx_post(
      state.zbx_api_url,
      "user.login",
      %{user: state.zbx_username, password: state.zbx_password},
      nil
    )
  end

  def get_hostgroup_id(state) do
    zbx_post(
      state.zbx_api_url,
      "hostgroup.get",
      %{output: ["extend"], filter: %{name: ["acari_clients"]}},
      state.auth
    )
  end

  def get_template_id(state) do
    zbx_post(
      state.zbx_api_url,
      "template.get",
      %{output: ["extend"], filter: %{host: ["acari_client"]}},
      state.auth
    )
  end

  def get_hosts(state, hostgroup_id) do
    zbx_post(
      state.zbx_api_url,
      "host.get",
      %{output: ["host"], groupids: [hostgroup_id]},
      state.auth
    )
  end

  def get_host(state, host_name) do
    zbx_post(
      state.zbx_api_url,
      "host.get",
      %{output: ["host", "hostid"], filter: %{host: [host_name]}},
      state.auth
    )
  end

  def get_host_items(state, host_id) do
    zbx_post(
      state.zbx_api_url,
      "item.get",
      %{hostids: host_id, output: ["key_", "value_type"]},
      state.auth
    )
  end

  def add_host_if_not_exists(state, host_name) do
    case state.hosts[host_name] do
      nil ->
        case get_host(state, host_name) do
          {:ok, [%{"host" => host_name, "hostid" => host_id}]} ->
            put_in(state, [Access.key(:hosts), host_name], %{hostid: host_id, items: %{}})

          _ ->
            add_host(state, host_name)
        end

      _ ->
        state
    end
  end

  def add_host(state, host_name) do
    request = %{
      host: host_name,
      interfaces: [
        %{
          type: 1,
          main: 1,
          useip: 1,
          ip: "127.0.0.1",
          dns: "",
          port: "10050"
        }
      ],
      groups: [
        %{
          groupid: state.hostgroup_id
        }
      ],
      templates: [
        %{
          templateid: state.template_id
        }
      ],
      inventory_mode: 1
    }

    case zbx_post(state.zbx_api_url, "host.create", request, state.auth) do
      {:ok, %{"hostids" => [host_id]}} ->
        put_in(state, [Access.key(:hosts), host_name], %{hostid: host_id, items: %{}})

      _ ->
        state
    end
  end

  defp zbx_post(zbx_api_url, method, params, auth) do
    with request <- request(method, params, auth),
         {:ok, %{status_code: 200, body: body_json}} <-
           HTTPoison.post(
             zbx_api_url,
             request,
             [
               {"Content-Type", "application/json-rpc"}
             ]
           ),
         {:ok, %{"result" => result}} <- Jason.decode(body_json) do
      {:ok, result}
    else
      {:ok, %{"error" => error}} ->
        case error["data"] |> String.contains?("re-login") do
          true ->
            Logger.error("zbx_api: Bad auth_token")
            Process.sleep(60_000)
            Process.exit(self(), :kill)

          _ ->
            {:error, {:no_result, error}}
        end

      {:ok, response} ->
        {:error, {:bad_response, response}}

      {:error, reason} ->
        {:error, reason}

      res ->
        {:error, res}
    end
  end

  defp zabbix_sender(state, host, key, value) do
    Task.start(fn ->
      case System.cmd("zabbix_sender", [
             "-z",
             state.zbx_snd_host,
             "-p",
             to_string(state.zbx_snd_port),
             "-s",
             host,
             "-k",
             key,
             "-o",
             to_string(value)
           ]) do
        {res, 0} -> Logger.debug("zabbix_sender: #{host}:#{key}=#{value}\n#{res}")
        {err, code} -> Logger.debug("zabbix_sender exits with code #{code}, output: #{err}")
      end
    end)
  end

  @impl true
  def handle_cast({:send, host, key, value}, state) do
    state = add_host_if_not_exists(state, host)
    zabbix_sender(state, host, key, value)
    {:noreply, state}
  end

  def handle_cast({:send_master, key, value}, state) do
    zabbix_sender(state, "acari_master", key, value)
    {:noreply, state}
  end

  # API
  def zbx_send(host, key, value) do
    GenServer.cast(__MODULE__, {:send, host, key, value})
  end

  def zbx_send_master(key, value) do
    GenServer.cast(__MODULE__, {:send_master, key, value})
  end
end
