defmodule AcariServer.Zabbix.ZbxConst do
  defmacro client_number_key, do: "bogatka.clients.number"
  defmacro client_active_key, do: "bogatka.clients.active"
  defmacro client_active_percent_key, do: "bogatka.clients.active.percent"
end

defmodule AcariServer.Zabbix.ZbxApi do
  require Logger
  require AcariServer.Zabbix.ZbxConst, as: ZbxConst
  use GenServer

  alias AcariServer.Mnesia

  @send_max_delay 3_000
  @send_delay 500
  @group_prefix "bg."
  @main_group "Bogatka_all"
  @main_template "Bogatka_client"
  @main_host "Bogatka_master"

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
      sender: %Sender{}
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  #  ██████  █████  ██      ██      ██████   █████   ██████ ██   ██ ███████
  # ██      ██   ██ ██      ██      ██   ██ ██   ██ ██      ██  ██  ██
  # ██      ███████ ██      ██      ██████  ███████ ██      █████   ███████
  # ██      ██   ██ ██      ██      ██   ██ ██   ██ ██      ██  ██       ██
  #  ██████ ██   ██ ███████ ███████ ██████  ██   ██  ██████ ██   ██ ███████

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
         {:ok, auth} <- Zabbix.API.login(state.zbx_username, state.zbx_password) do
      hosts_sync()
      Logger.info("Zabbix API successfully init")

      {:noreply, %State{state | auth: auth}}
    else
      res ->
        Logger.error("Can't init zabbix API(#{state.zbx_api_url}): #{inspect(res)}")
        Process.sleep(60_000)
        {:stop, :shutdown, state}
    end
  end

  @impl true
  def handle_cast({:send, host, key, value}, state) do
    zabbix_sender(state, host, key, value)
  end

  def handle_cast({:send_master, key, value}, state) do
    zabbix_sender(state, @main_host, key, value)
  end

  def handle_cast(:groups_sync, state) do
    groups_sync()
    {:noreply, state}
  end

  def handle_cast({:hosts_sync, opts}, state) do
    hosts_sync(opts)
    {:noreply, state}
  end

  def handle_cast({:add_host, node}, state) do
    add_host(node)
    {:noreply, state}
  end

  def handle_cast({:update_host, node, old_name}, state) do
    update_host(node, old_name)
    {:noreply, state}
  end

  def handle_cast({:del_host, name}, state) do
    del_host(name)
    {:noreply, state}
  end

  @impl true
  def handle_info(:time_to_send, state) do
    zabbix_sender(state)
  end

  # ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██
  # ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██
  # █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██
  # ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██
  # ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████

  defp get_main_group() do
    case zbx_post("hostgroup.get", %{output: ["name"], filter: %{name: [@main_group]}}) do
      {:ok, list} -> list
      _ -> []
    end
  end

  defp get_template_id() do
    case zbx_post(
           "template.get",
           %{output: ["extend"], filter: %{host: [@main_template]}}
         ) do
      {:ok, list} -> list
      _ -> []
    end
  end

  defp get_bg_groups() do
    case zbx_post("hostgroup.get", %{output: ["name"]}) do
      {:ok, list} ->
        list
        |> Enum.filter(fn
          %{"name" => @group_prefix <> _name} -> true
          _ -> false
        end)

      _ ->
        []
    end
  end

  defp get_hosts(hostgroup_id) do
    case zbx_post(
           "host.get",
           %{output: ["host"], groupids: [hostgroup_id]}
         ) do
      {:ok, list} -> list
      _ -> []
    end
  end

  def del_host(name) do
    case zbx_post(
           "host.get",
           %{output: ["hostid"], filter: %{host: [name]}}
         ) do
      {:ok, [%{"hostid" => id}]} -> zbx_post("host.delete", [id])
      _ -> nil
    end
  end

  defp groups_sync() do
    # Delete old groups
    groups = AcariServer.GroupManager.list_groups()

    groups_list =
      groups
      |> Enum.map(fn %{name: name} -> name end)

    zbx_groups = get_bg_groups()

    zbx_groups_id_del_list =
      zbx_groups
      |> Enum.reject(fn %{"name" => @group_prefix <> name} -> Enum.member?(groups_list, name) end)
      |> Enum.map(fn %{"groupid" => id} -> id end)

    case zbx_groups_id_del_list do
      [] ->
        nil

      _ ->
        zbx_post("hostgroup.delete", zbx_groups_id_del_list)
    end

    # Add new groups
    zbx_groups_name_list =
      zbx_groups
      |> Enum.map(fn %{"name" => @group_prefix <> name} -> name end)

    groups
    |> Enum.reject(fn %{name: name} -> Enum.member?(zbx_groups_name_list, name) end)
    |> Enum.each(fn group ->
      zbx_post("hostgroup.create", %{name: @group_prefix <> group.name})
    end)

    Mnesia.update_zbx_hostgroup(get_main_group() ++ get_bg_groups())
  end

  defp hosts_sync(opt \\ []) do
    with [%{"groupid" => hostgroup_id}] <- get_main_group(),
         nodes = [_ | _] <- AcariServer.NodeManager.list_nodes_wo_preload() do
      groups_sync()
      # Delete old hosts
      node_name_list =
        nodes
        |> Enum.map(fn %{name: name} -> name end)

      zbx_hosts = get_hosts(hostgroup_id)

      zbx_hostid_del_list =
        zbx_hosts
        |> Enum.reject(fn %{"host" => host} -> Enum.member?(node_name_list, host) end)
        |> Enum.map(fn %{"hostid" => id} -> id end)

      case zbx_hostid_del_list do
        [] ->
          nil

        list when length(list) / length(node_name_list) > 0.1 and length(list) > 10 ->
          Logger.warn("Zabbix: too many hosts to delete")

        list ->
          zbx_post("host.delete", list)
      end

      # Add new hosts
      zbx_hosts_name_list =
        zbx_hosts
        |> Enum.map(fn %{"host" => host} -> host end)

      nodes
      |> Enum.reject(fn %{name: name} -> Enum.member?(zbx_hosts_name_list, name) end)
      |> Enum.each(fn node ->
        add_host(node)
      end)

      if opt[:update], do: Task.start(fn -> nodes |> hosts_update() end)
    else
      _ -> []
    end
  end

  defp hosts_update(nodes) do
    nodes
    |> Enum.each(fn node ->
      update_host(node, node.name)
    end)
  end

  defp add_host(node) do
    add_or_update_host(node, "create")
  end

  defp update_host(node, old_name) do
    case zbx_post(
           "host.get",
           %{output: ["hostid"], filter: %{host: [old_name]}}
         ) do
      {:ok, [%{"hostid" => id}]} ->
        node = AcariServer.Repo.preload(node, :groups)

        with true <- old_name == node.name,
             {:ok, zbx_group_list} <-
               zbx_post(
                 "hostgroup.get",
                 %{output: ["name"], hostids: id}
               ),
             zbx_group_list <-
               zbx_group_list
               |> Enum.map(fn
                 %{"name" => @group_prefix <> name} -> name
                 _ -> nil
               end)
               |> Enum.filter(& &1)
               |> Enum.sort(),
             group_list <-
               node.groups
               |> Enum.map(fn %{name: name} -> name end)
               |> Enum.sort(),
             true <- zbx_group_list == group_list do
          nil
        else
          _ ->
            add_or_update_host(node, "update", id)
        end

      _ ->
        nil
    end
  end

  defp add_or_update_host(node, method, hostid \\ nil) do
    with [%{"templateid" => template_id}] <- get_template_id(),
         [%{"groupid" => hostgroup_id}] <- get_main_group() do
      group_list =
        node
        |> AcariServer.Repo.preload(:groups)
        |> Map.get(:groups)
        |> Enum.map(fn %{name: name} -> @group_prefix <> name end)
        |> Mnesia.get_zbx_hostgroup_id_list()
        |> Enum.map(fn id -> %{groupid: id} end)

      params = %{
        host: node.name,
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
            groupid: hostgroup_id
          }
          | group_list
        ],
        templates: [
          %{
            templateid: template_id
          }
        ],
        inventory_mode: 1
      }

      params = if hostid, do: Map.put(params, :hostid, hostid), else: params

      zbx_post("host." <> method, params)
    end
  end

  def create_master_host() do
    case zbx_post(
           "host.get",
           %{output: ["hostid"], filter: %{host: [@main_host]}}
         ) do
      {:ok, [%{"hostid" => _id}]} ->
        nil

      _ ->
        with {:ok, %{"groupids" => [hostgroup_id]}} <-
               (case zbx_post("hostgroup.get", %{
                       output: ["groupid"],
                       filter: %{name: [@main_host]}
                     }) do
                  {:ok, [%{"groupid" => id}]} ->
                    {:ok, %{"groupids" => [id]}}

                  _ ->
                    zbx_post("hostgroup.create", %{name: @main_host})
                    |> IO.inspect()
                end) do
          params = %{
            host: @main_host,
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
                groupid: hostgroup_id
              }
            ],
            inventory_mode: 1
          }

          case zbx_post("host.create", params) do
            {:ok, %{"hostids" => [hostid]}} ->
              zbx_post(
                "item.create",
                %{
                  key_: ZbxConst.client_number_key(),
                  name: "Количество клиентов",
                  hostid: hostid,
                  # zabbix trapper
                  type: 2,
                  # numeric unsigned
                  value_type: 3
                }
              )
              |> IO.inspect()

              zbx_post(
                "item.create",
                %{
                  key_: ZbxConst.client_active_key(),
                  name: "Количество активных клиентов",
                  hostid: hostid,
                  # zabbix trapper
                  type: 2,
                  # numeric unsigned
                  value_type: 3
                }
              )
              |> IO.inspect()

              zbx_post(
                "item.create",
                %{
                  key_: ZbxConst.client_active_percent_key(),
                  name: "Процент активных клиентов",
                  hostid: hostid,
                  # Вычисляемый
                  type: 15,
                  # с плавающей точкой
                  value_type: 0,
                  delay: "30s",
                  params:
                    "100*last(\"#{ZbxConst.client_active_key()}\")/last(\"#{
                      ZbxConst.client_number_key()
                    }\")",
                  units: "%"
                }
              )
              |> IO.inspect()

            _ ->
              nil
          end
        end
    end
  end

  def zbx_post(method, params) do
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

  # ███████ ███████ ███    ██ ██████  ███████ ██████
  # ██      ██      ████   ██ ██   ██ ██      ██   ██
  # ███████ █████   ██ ██  ██ ██   ██ █████   ██████
  #      ██ ██      ██  ██ ██ ██   ██ ██      ██   ██
  # ███████ ███████ ██   ████ ██████  ███████ ██   ██

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
    request =
      ZabbixSender.Protocol.encode_request(sender.value_list, nil)
      |> ZabbixSender.Serializer.serialize()

    with {:ok, response} <- ZabbixSender.send(request, state.zbx_snd_host, state.zbx_snd_port),
         {:ok, deserialized} <- ZabbixSender.Serializer.deserialize(response),
         {:ok, decoded} <- ZabbixSender.Protocol.decode_response(deserialized) do
      if decoded.failed == 0 do
        # Logger.debug("zabbix_sender: #{decoded.processed} values processed")
      else
        # Logger.warn(
        #   "zabbix_sender: #{decoded.processed} values processed out of #{decoded.total}"
        # )
      end
    else
      res -> Logger.error("zabbix_sender: #{inspect(res)}")
    end

    {:noreply, %State{state | sender: %Sender{}}}
  end

  #  █████  ██████  ██
  # ██   ██ ██   ██ ██
  # ███████ ██████  ██
  # ██   ██ ██      ██
  # ██   ██ ██      ██

  def zbx_send(host, key, value) do
    GenServer.cast(__MODULE__, {:send, host, key, value})
  end

  def zbx_send_master(key, value) do
    GenServer.cast(__MODULE__, {:send_master, key, value})
  end

  def zbx_groups_sync() do
    GenServer.cast(__MODULE__, :groups_sync)
  end

  def zbx_hosts_sync(opts \\ []) do
    GenServer.cast(__MODULE__, {:hosts_sync, opts})
  end

  def zbx_add_host(node) do
    GenServer.cast(__MODULE__, {:add_host, node})
  end

  def zbx_update_host(node, old_name) do
    GenServer.cast(__MODULE__, {:update_host, node, old_name})
  end

  def zbx_del_host(name) do
    GenServer.cast(__MODULE__, {:del_host, name})
  end
end
