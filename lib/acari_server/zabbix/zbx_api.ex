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
      :zbx_api_url_2,
      :zbx_snd_host,
      :zbx_snd_port,
      :zbx_snd_host_2,
      :zbx_snd_port_2,
      :zbx_username,
      :zbx_username_2,
      :zbx_password,
      :zbx_password_2,
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
    with url when is_binary(url) <- Application.get_env(:acari_server, :zabbix)[:zbx_api_url],
         [url | _] <- String.split(url),
         %URI{} = uri <- URI.parse(url),
         scheme when is_binary(scheme) <- uri.scheme,
         host when is_binary(host) <- uri.host do
      url = "#{uri.scheme}://#{uri.host}:#{uri.port || 80}#{uri.path}"
      zbx_snd_host = Application.get_env(:acari_server, :zabbix)[:zbx_snd_host] || "localhost"

      zbx_snd_port = Application.get_env(:acari_server, :zabbix)[:zbx_snd_port] || 10051

      {zbx_username, zbx_password} =
        case Regex.run(~r{^([^:]+):?(.*)}, uri.userinfo || "") do
          [_, name, pass] ->
            {(name != "" && name) || "Admin", (pass != "" && pass) || "acari&zabbix"}

          _ ->
            {"Admin", "acari&zabbix"}
        end

      {url_2, zbx_username_2, zbx_password_2, zbx_snd_host_2, zbx_snd_port_2} =
        with url when is_binary(url) <-
               Application.get_env(:acari_server, :zabbix)[:zbx_api_url_2],
             [url | _] <- String.split(url),
             %URI{} = uri <- URI.parse(url),
             scheme when is_binary(scheme) <- uri.scheme,
             host when is_binary(host) <- uri.host do
          url = "#{uri.scheme}://#{uri.host}:#{uri.port || 80}#{uri.path}"

          {zbx_username, zbx_password} =
            case Regex.run(~r{^([^:]+):?(.*)}, uri.userinfo || "") do
              [_, name, pass] ->
                {(name != "" && name) || "Admin", (pass != "" && pass) || "acari&zabbix"}

              _ ->
                {"Admin", "acari&zabbix"}
            end

          zbx_snd_host = Application.get_env(:acari_server, :zabbix)[:zbx_snd_host_2]
          zbx_snd_port = Application.get_env(:acari_server, :zabbix)[:zbx_snd_port_2] || 10051

          {url, zbx_username, zbx_password, zbx_snd_host, zbx_snd_port}
        else
          _ -> {nil, nil, nil, nil, nil}
        end

      {:ok,
       %State{
         zbx_api_url: url,
         zbx_api_url_2: url_2,
         zbx_snd_host: zbx_snd_host,
         zbx_snd_port: zbx_snd_port,
         zbx_snd_host_2: zbx_snd_host_2,
         zbx_snd_port_2: zbx_snd_port_2,
         zbx_username: zbx_username,
         zbx_password: zbx_password,
         zbx_username_2: zbx_username_2,
         zbx_password_2: zbx_password_2
       }, {:continue, :init}}
    else
      _ ->
        Logger.warn("Zabbix: No URL for zabbix server")
        :ignore
    end
  end

  defp zbx_auth(url, username, password) do
    with :ok <- Zabbix.API.create_client(url),
         {:ok, auth} <- Zabbix.API.login(username, password) do
      {:ok, auth}
    else
      res -> res
    end
  end

  defp double_zbx(state, func) do
    if state.zbx_api_url_2 do
      case zbx_auth(state.zbx_api_url_2, state.zbx_username_2, state.zbx_password_2) do
        {:ok, _} -> func.()
        _ -> nil
      end

      zbx_auth(state.zbx_api_url, state.zbx_username, state.zbx_password)
    end

    func.()
  end

  @impl true
  def handle_continue(:init, state) do
    with {:ok, auth} <- zbx_auth(state.zbx_api_url, state.zbx_username, state.zbx_password),
         {:main_group, [%{"groupid" => _}]} <- {:main_group, get_main_group()},
         {:main_usrgroup, [%{"usrgrpid" => _}]} <- {:main_usrgroup, get_main_usrgroup()},
         {:main_template, [%{"templateid" => _}]} <- {:main_template, get_template_id()} do
      create_master_host()
      hosts_sync()
      Logger.info("Zabbix API successfully init")

      url_2 =
        with url_2 when is_binary(url_2) <- state.zbx_api_url_2,
             {:ok, _auth} <- zbx_auth(url_2, state.zbx_username_2, state.zbx_password_2),
             {:main_group, [%{"groupid" => _}]} <- {:main_group, get_main_group()},
             {:main_usrgroup, [%{"usrgrpid" => _}]} <- {:main_usrgroup, get_main_usrgroup()},
             {:main_template, [%{"templateid" => _}]} <- {:main_template, get_template_id()} do
          create_master_host()
          hosts_sync()
          Logger.info("Aux Zabbix API successfully init")

          url_2
        else
          res ->
            Logger.error(
              "Can't init aux zabbix API(#{inspect(state.zbx_api_url_2)}): #{inspect(res)}"
            )

            nil
        end

      {:noreply, %State{state | auth: auth, zbx_api_url_2: url_2}}
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
    double_zbx(state, fn -> groups_sync() end)
    {:noreply, state}
  end

  def handle_cast(:users_sync, state) do
    double_zbx(state, fn -> users_sync() end)
    {:noreply, state}
  end

  def handle_cast({:hosts_sync, opts}, state) do
    double_zbx(state, fn -> hosts_sync(opts) end)
    {:noreply, state}
  end

  def handle_cast({:add_host, node}, state) do
    double_zbx(state, fn -> add_host(node) end)
    {:noreply, state}
  end

  def handle_cast({:update_host, node, old_name}, state) do
    double_zbx(state, fn -> update_host(node, old_name) end)
    {:noreply, state}
  end

  def handle_cast({:del_host, name}, state) do
    double_zbx(state, fn -> del_host(name) end)
    {:noreply, state}
  end

  def handle_cast({:exec_api, client_name, template}, state) do
    exec_api(client_name, template)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_hostid, name}, _from, state) do
    hostid = get_hostid(name)
    {:reply, hostid, state}
  end

  def handle_call({:get_api_url, n}, _from, state) do
    url =
      case n do
        2 -> state.zbx_api_url_2
        _ -> state.zbx_api_url
      end

    {:reply, url, state}
  end

  @impl true
  def handle_info(:time_to_send, state) do
    zabbix_sender(state)
  end

  def handle_info(mes, state) do
    Logger.error("ZabbixAPI: unknown handle_info message: #{inspect(mes)}")
    {:noreply, state}
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

  defp get_main_usrgroup() do
    case zbx_post("usergroup.get", %{output: ["name"], filter: %{name: [@main_group]}}) do
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

  defp get_bg_usrgroups() do
    case zbx_post("usergroup.get", %{output: ["name"]}) do
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

  defp del_host(name) do
    case zbx_post(
           "host.get",
           %{output: ["hostid"], filter: %{host: [name]}}
         ) do
      {:ok, [%{"hostid" => id}]} -> zbx_post("host.delete", [id])
      _ -> nil
    end
  end

  defp get_hostid(name) do
    case zbx_post(
           "host.get",
           %{output: ["hostid"], filter: %{host: [name]}}
         ) do
      {:ok, [%{"hostid" => id}]} -> id
      _ -> nil
    end
  end

  def exec_api(client_name, tag) do
    {script, _} = AcariServer.SFX.create_script_from_template(client_name, tag, %{})

    prefix = "alias AcariServer.Zabbix.ZbxApi\n"

    {res, _} =
      try do
        try do
          Code.eval_string(prefix <> script, [client_name: client_name], file: tag)
        catch
          sig, mes -> {inspect({sig, mes}), nil}
        end
      rescue
        x ->
          {inspect(x), nil}
      end

    AcariServer.Master.set_script(
      client_name,
      tag,
      case res do
        str when is_binary(str) -> str
        res -> inspect(res, pretty: true)
      end
    )
  end

  defp groups_sync() do
    # Delete old groups
    groups = AcariServer.GroupManager.list_groups()

    groups_list =
      groups
      |> Enum.map(fn %{name: name} -> name end)

    zbx_groups = get_bg_groups()

    # Delete groups
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

    # Delete user groups
    zbx_usrgroups = get_bg_usrgroups()

    zbx_usrgroups_id_del_list =
      zbx_usrgroups
      |> Enum.reject(fn %{"name" => @group_prefix <> name} -> Enum.member?(groups_list, name) end)
      |> Enum.map(fn %{"usrgrpid" => id} -> id end)

    case zbx_usrgroups_id_del_list do
      [] ->
        nil

      _ ->
        zbx_post("usergroup.delete", zbx_usrgroups_id_del_list)
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

    bg_groups = get_bg_groups()

    zbx_usrgroups_name_list =
      zbx_usrgroups
      |> Enum.map(fn %{"name" => name} -> name end)

    bg_groups
    |> Enum.reject(fn %{"name" => name} -> Enum.member?(zbx_usrgroups_name_list, name) end)
    |> Enum.each(fn %{"groupid" => id, "name" => name} ->
      zbx_post(
        "usergroup.create",
        %{
          name: name,
          rights: %{
            id: id,
            permission: 2
          }
        }
      )
    end)

    Mnesia.update_zbx_hostgroup(bg_groups)
  end

  defp get_users(usrgrpid) do
    case zbx_post(
           "user.get",
           %{output: ["alias"], usrgrpids: [usrgrpid]}
         ) do
      {:ok, list} -> list
      _ -> []
    end
  end

  defp users_sync() do
    with [%{"usrgrpid" => usrgrpid}] <- get_main_usrgroup() do
      users =
        AcariServer.UserManager.list_users()
        |> Enum.reject(fn %{is_admin: admin} -> admin end)
        |> Enum.map(fn %{username: name, groups: groups_list} ->
          {name, groups_list |> Enum.map(fn %{name: name} -> @group_prefix <> name end)}
        end)
        |> Enum.into(%{})

      # Delete
      users_list =
        users
        |> Enum.map(fn {name, _} -> name end)

      zbx_users_list_to_delete =
        get_users(usrgrpid)
        |> Enum.reject(fn %{"alias" => name} ->
          Enum.member?(users_list, name)
        end)
        |> Enum.map(fn %{"userid" => userid} -> userid end)

      zbx_post("user.delete", zbx_users_list_to_delete)

      usrgrp_name_id_map =
        get_bg_usrgroups()
        |> Enum.map(fn %{"name" => name, "usrgrpid" => usrgrpid} ->
          {name, usrgrpid}
        end)
        |> Enum.into(%{})

      # Update
      zbx_users = get_users(usrgrpid)

      params =
        zbx_users
        |> Enum.map(fn %{"alias" => name, "userid" => userid} ->
          usrgrpid_list =
            users[name]
            |> Enum.map(fn usergroup_name -> %{usrgrpid: usrgrp_name_id_map[usergroup_name]} end)

          %{
            userid: userid,
            usrgrps: [%{usrgrpid: usrgrpid} | usrgrpid_list]
          }
        end)

      zbx_post("user.update", params)

      # Create

      zbx_users_list =
        zbx_users
        |> Enum.map(fn %{"alias" => name} -> name end)

      # params =
      users
      |> Enum.reject(fn {name, _} -> Enum.member?(zbx_users_list, name) end)
      |> Enum.map(fn {name, usrgrp_list} ->
        usrgrpid_list =
          usrgrp_list
          |> Enum.map(fn usergroup_name -> %{usrgrpid: usrgrp_name_id_map[usergroup_name]} end)

        %{
          alias: name,
          passwd: :crypto.strong_rand_bytes(12) |> Base.encode64(),
          lang: "ru_RU",
          usrgrps: [%{usrgrpid: usrgrpid} | usrgrpid_list]
        }
      end)
      |> Enum.each(fn params ->
        zbx_post("user.create", params)
      end)
    else
      _ -> nil
    end
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
           %{output: ["hostid", "name"], filter: %{host: [old_name]}}
         ) do
      {:ok, [%{"hostid" => id, "name" => zbx_name}]} ->
        node = AcariServer.Repo.preload(node, :groups)

        with true <- old_name == node.name,
             true <- zbx_name == node.description,
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
        add_or_update_host(node, "create")
    end
  end

  defp add_or_update_host(node, method, hostid \\ nil)
  defp add_or_update_host(%{lock: true}, _method, _hostid), do: nil

  defp add_or_update_host(node, method, hostid) do
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
        name: node.description,
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

  defp create_master_host() do
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

  # Public function

  def get_item_id(name, key) do
    with {:ok, list} <-
           zbx_post("item.get", %{host: name, output: ["itemid", "key_"], search: %{key_: key}}) do
      list
    else
      _ -> []
    end
    |> Enum.reduce_while(nil, fn
      %{"itemid" => id, "key_" => ^key}, _ -> {:halt, id}
      _, _ -> {:cont, nil}
    end)
  end

  def get_history(params) do
    with {:ok, list} <- zbx_post("history.get", params) do
      list
    else
      _ -> []
    end
  end

  defdelegate utc_to_local(ts), to: AcariServer, as: :get_local_date

  def timestamp(nt) do
    NaiveDateTime.to_erl(nt)
    |> :calendar.local_time_to_universal_time()
    |> :erlang.universaltime_to_posixtime()
    |> to_string()
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

    zabbix_sender_send(request, state.zbx_snd_host, state.zbx_snd_port)

    if state.zbx_snd_host_2 do
      zabbix_sender_send(request, state.zbx_snd_host_2, state.zbx_snd_port_2)
    end

    # with {:ok, response} <- ZabbixSender.send(request, state.zbx_snd_host, state.zbx_snd_port),
    #      {:ok, deserialized} <- ZabbixSender.Serializer.deserialize(response),
    #      {:ok, decoded} <- ZabbixSender.Protocol.decode_response(deserialized) do
    #   if decoded.failed == 0 do
    #     # Logger.debug("zabbix_sender: #{decoded.processed} values processed")
    #   else
    #     # Logger.warn(
    #     #   "zabbix_sender: #{decoded.processed} values processed out of #{decoded.total}"
    #     # )
    #   end
    # else
    #   res -> Logger.error("zabbix_sender: #{inspect(res)}")
    # end

    {:noreply, %State{state | sender: %Sender{}}}
  end

  @zabbix_sender_timeout 5_000
  defp zabbix_sender_send(request, host, port) do
    task =
      Task.Supervisor.async_nolink(AcariServer.TaskSup, ZabbixSender, :send, [request, host, port])

    # task = Task.Supervisor.async_nolink(AcariServer.TaskSup, fn -> Process.exit(self(), :kill) end)

    case Task.yield(task, @zabbix_sender_timeout) || Task.shutdown(task) do
      {:ok, {:ok, _response}} ->
        :ok

      {:ok, res} ->
        Logger.error("zabbix_sender: #{inspect(res)}")

      nil ->
        Logger.warn("zabbix_sender: failed to get a result in #{@zabbix_sender_timeout}ms")

      res ->
        Logger.error("zabbix_sender: #{inspect(res)}")
    end
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

  def zbx_users_sync() do
    GenServer.cast(__MODULE__, :users_sync)
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

  def zbx_get_host_id(name) do
    GenServer.call(__MODULE__, {:get_hostid, name})
  end

  def zbx_exec_api(client_name, template) do
    GenServer.cast(__MODULE__, {:exec_api, client_name, template})
  end

  def zbx_get_api_url() do
    GenServer.call(__MODULE__, {:get_api_url, 0})
  end

  def zbx_get_api_url2() do
    GenServer.call(__MODULE__, {:get_api_url, 2})
  end
end
