defmodule AcariServer.Zabbix.ZbxApi do
  require Logger
  use GenServer

  @send_max_delay 3_000
  @send_delay 500

  defmodule Sender do
    defstruct [
      :timer_ref,
      :snd_time,
      value_list: []
    ]
  end

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
      hosts: %{},
      sender: %Sender{}
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
           zbx_api_url: url,
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
    with :ok <- Zabbix.API.create_client(state.zbx_api_url),
         {:ok, auth} <- Zabbix.API.login(state.zbx_username, state.zbx_password),
         state <- %State{state | auth: auth},
         {:ok, [%{"groupid" => hostgroup_id}]} <- get_hostgroup_id(),
         {:ok, [%{"templateid" => template_id}]} <- get_template_id(),
         {:ok, hosts} <- get_hosts(hostgroup_id),
         hosts <-
           hosts
           |> Enum.map(fn %{"host" => host_name, "hostid" => host_id} ->
             items = get_host_items(host_id)

             {host_name, %{hostid: host_id, items: items}}
           end)
           |> Enum.into(%{}) do
      Logger.info("Zabbix API successfully init")

      hosts = del_unconfigured_hosts(hosts)

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
        Logger.error("Can't init zabbix API(#{state.zbx_api_url}): #{inspect(res)}")
        Process.sleep(60_000)
        {:stop, :shutdown, state}
    end
  end

  defp get_hostgroup_id() do
    zbx_post("hostgroup.get", %{output: ["extend"], filter: %{name: ["acari_clients"]}})
  end

  defp get_template_id() do
    zbx_post(
      "template.get",
      %{output: ["extend"], filter: %{host: ["acari_client"]}}
    )
  end

  defp get_hosts(hostgroup_id) do
    zbx_post(
      "host.get",
      %{output: ["host"], groupids: [hostgroup_id]}
    )
  end

  defp get_host(host_name) do
    zbx_post(
      "host.get",
      %{output: ["host", "hostid"], filter: %{host: [host_name]}}
    )
  end

  defp get_host_items(host_id) do
    case zbx_post(
           "item.get",
           %{hostids: host_id, output: ["key_", "value_type"]}
         ) do
      {:ok, items} ->
        items
        |> Enum.map(fn %{"key_" => key} = item ->
          nil
          {key, item}
        end)
        |> Enum.into(%{})

      _ ->
        %{}
    end
  end

  defp add_host_if_not_exists(state, host_name) do
    case state.hosts[host_name] do
      nil ->
        case get_host(host_name) do
          {:ok, [%{"host" => host_name, "hostid" => host_id}]} ->
            put_in(state, [Access.key(:hosts), host_name], %{
              hostid: host_id,
              items: get_host_items(host_id)
            })

          _ ->
            add_host(state, host_name)
        end

      _ ->
        state
    end
  end

  defp add_host(state, host_name) do
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

    case zbx_post("host.create", request) do
      {:ok, %{"hostids" => [host_id]}} ->
        put_in(state, [Access.key(:hosts), host_name], %{
          hostid: host_id,
          items: get_host_items(host_id)
        })

      _ ->
        state
    end
  end

  defp del_hosts(host_id_list) do
    zbx_post("host.delete", host_id_list)
  end

  defp del_unconfigured_hosts(hosts) do
    node_name_list =
      AcariServer.NodeManager.list_nodes_wo_preload()
      |> Enum.map(fn %{name: name} -> name end)

    host_id_list =
      hosts
      |> Enum.reduce([], fn {name, %{hostid: host_id}}, acc ->
        case Enum.member?(node_name_list, name) do
          false -> [host_id | acc]
          _ -> acc
        end
      end)

    case host_id_list do
      [] ->
        hosts

      list ->
        case del_hosts(list) do
          {:ok, %{"hostids" => list}} ->
            hosts
            |> Enum.reject(fn {_name, %{hostid: host_id}} -> Enum.member?(list, host_id) end)
            |> Enum.into(%{})

          {:error, res} ->
            Logger.error("Can't delete unconfigured hosts: #{inspect(res)}")
            hosts
        end
    end
  end

  defp zbx_post(method, params) do
    with {:ok, %{"result" => result}} <- Zabbix.API.call(method, params) do
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

  @impl true
  def handle_cast({:send, host, key, value}, state) do
    state = add_host_if_not_exists(state, host)

    case state.hosts[host][:items][key] do
      nil ->
        Logger.warn("Zabbix sender: bad key '#{key}' for host #{host}")
        {:noreply, state}

      _ ->
        zabbix_sender(state, host, key, value)
    end
  end

  def handle_cast({:send_master, key, value}, state) do
    zabbix_sender(state, "acari_master", key, value)
  end

  def handle_cast(:del_sync, state) do
    {:noreply, %State{state | hosts: del_unconfigured_hosts(state.hosts)}}
  end

  @impl true
  def handle_info(:time_to_send, state) do
    zabbix_sender(state)
  end

  defp zabbix_sender(%{sender: sender} = state, host, key, value) do
    value = ZabbixSender.Protocol.value(host, key, value, nil)

    ts = :erlang.system_time(:millisecond)

    snd_time = sender.snd_time || ts + @send_max_delay
    delay = min(@send_delay, snd_time - ts)
    delay = (delay < 0 && 0) || delay

    if is_reference(sender.timer_ref), do: Process.cancel_timer(sender.timer_ref)

    ref = Process.send_after(self(), :time_to_send, delay)
    sender = %Sender{timer_ref: ref, snd_time: snd_time, value_list: [value | sender.value_list]}
    {:noreply, %State{state | sender: sender}}
  end

  defp zabbix_sender(%{sender: sender} = state) do
    :erlang.system_time(:millisecond)

    request =
      ZabbixSender.Protocol.encode_request(sender.value_list, nil)
      |> ZabbixSender.Serializer.serialize()

    with {:ok, response} <- ZabbixSender.send(request, state.zbx_snd_host, state.zbx_snd_port),
         {:ok, deserialized} <- ZabbixSender.Serializer.deserialize(response),
         {:ok, decoded} <- ZabbixSender.Protocol.decode_response(deserialized) do
      if decoded.failed == 0 do
        Logger.debug("zabbix_sender: #{decoded.processed} values processed")
      else
        Logger.warn(
          "zabbix_sender: #{decoded.processed} values processed out of #{decoded.total}"
        )
      end
    else
      res -> Logger.error("zabbix_sender: #{inspect(res)}")
    end

    {:noreply, %State{state | sender: %Sender{}}}
  end

  # API
  def zbx_send(host, key, value) do
    GenServer.cast(__MODULE__, {:send, host, key, value})
  end

  def zbx_send_master(key, value) do
    GenServer.cast(__MODULE__, {:send_master, key, value})
  end

  def zbx_sync_deleted_hosts() do
    GenServer.cast(__MODULE__, :del_sync)
  end
end
