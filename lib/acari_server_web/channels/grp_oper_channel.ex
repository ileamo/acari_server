defmodule AcariServerWeb.GrpOperChannel do
  use Phoenix.Channel, log_join: :debug, log_handle_in: false

  def join("grp_oper:" <> _id, _payload, socket) do
    user = AcariServer.UserManager.get_user(socket.assigns[:current_user_id])
    {:ok, assign(socket, :user, user)}
  end

  def handle_in("input", params, socket) do
    case params["cmd"] do
      "select" ->
        nodes =
          case params["group_id"] do
            "false" ->
              []

            "nil" ->
              AcariServer.NodeManager.list_nodes(socket.assigns[:user])

            id ->
              AcariServer.GroupManager.get_group!(id).nodes
          end

        id_name =
          nodes
          |> get_class_list()
          |> Enum.map(fn {id, class} -> {id, class.name} end)

        nodes =
          nodes
          |> node_filter(params["filter"], socket)

        %{common_script: cs, class_list: cl} =
          get_group_scripts(
            nodes,
            case params["script_type"] do
              "zabbix" -> :zabbix
              "server" -> :local
              _ -> :templates
            end
          )

        script_list =
          case params["class_id"] do
            "nil" ->
              cs

            class_id ->
              cl
              |> Enum.find(fn
                {{id, _}, _} -> id == String.to_integer(class_id)
                _ -> false
              end)
              |> case(
                do:
                  (
                    {_, l} -> l
                    _ -> cs
                  )
              )
          end
          |> Enum.sort()

        push(socket, "output", %{
          id: "select",
          class_id:
            if params["class_id"] == "nil" or
                 Enum.find(id_name, fn {id, _} ->
                   id == params["class_id"] |> String.to_integer()
                 end) do
              params["class_id"]
            else
              "nil"
            end,
          class_list:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "class_list.html",
              class_list: id_name
            ),
          script_list:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "script_list.html",
              script_list: script_list
            )
        })

      "get_filter" ->
        node_list =
          get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"],
            filter_show: true
          )

        push(socket, "output", %{
          id: "script",
          data:
            Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "oper_res_filter.html",
              node_list: node_list
            )
        })

      "get_script" ->
        case params["template_name"] do
          nil ->
            push(socket, "output", %{
              id: "script",
              opt: "Скрипт не определен",
              data:
                "Количество узлов в группе: #{
                  get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])
                  |> length()
                }"
            })

          tag ->
            get_script(
              socket,
              params["script_type"],
              tag,
              params["group_id"],
              params["class_id"],
              params["filter"]
            )
        end

      "get_script_multi" ->
        case params["template_name_list"] do
          [] ->
            push(socket, "output", %{
              id: "script",
              opt: "Невыбран ни один скрипт",
              data:
                "Количество узлов в группе: #{
                  get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])
                  |> length()
                }"
            })

          tag_list ->
            get_script_multi(
              socket,
              tag_list,
              params["group_id"],
              params["class_id"],
              params["filter"]
            )
        end

      "script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          ts = :os.system_time(:second)

          nodes_list =
            get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])

          (clients_list = get_exec_nodes_list(nodes_list, socket, tag))
          |> Enum.each(fn %{name: name} ->
            case params["script_type"] do
              "server" ->
                AcariServer.Mnesia.get_up_servers(:system_name)
                |> Enum.each(fn node ->
                  AcariServer.Mnesia.update_tun_srv_state(name, tag, node, %{reqv_ts: ts})
                end)

                AcariServer.Master.run_script_on_all_servers(name, tag)

              "zabbix" ->
                AcariServer.Mnesia.update_tun_state(name, tag, %{reqv_ts: ts})
                AcariServer.Zabbix.ZbxApi.zbx_exec_api(name, tag)

              _ ->
                AcariServer.Mnesia.update_tun_state(name, tag, %{reqv_ts: ts})
                AcariServer.Master.exec_script_on_peer(name, tag)
            end
          end)

          AcariServer.AuditManager.create_audit_log(
            socket,
            :tunnels,
            (params["script_type"] == "server" && "server_script") || "client_script",
            %{
              "template_name" => tag,
              "clients_list" => clients_list |> Enum.map(fn %{id: id} -> to_string(id) end),
              "group" => params["group_id"],
              "class" => params["class_id"],
              "filter" => params["filter"]
            }
          )

          Process.sleep(1_000)
          get_script(socket, params["script_type"], tag, nodes_list)
        else
          _ ->
            push(socket, "output", %{
              id: "script",
              data:
                "<pre><code>                            ^\n" <>
                  "Выберите скрипт из меню ----|</code></pre>",
              opt: "Скрипт не определен"
            })
        end

      "repeat_script" ->
        with tag when is_binary(tag) <- params["template_name"] do
          nodes_list =
            get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])

          exec_nodes_list = get_exec_nodes_list(nodes_list, socket, tag)

          case params["script_type"] do
            "server" ->
              exec_nodes_list
              |> Enum.reduce([], fn %{name: name}, acc ->
                servers = AcariServer.Mnesia.get_tunnel_srv_state(name)[tag] || %{}

                servers =
                  AcariServer.Mnesia.get_up_servers(:system_name)
                  |> Enum.filter(fn serv_name ->
                    case servers[serv_name] do
                      %{timestamp: ts, reqv_ts: reqv_ts} -> ts < reqv_ts
                      %{timestamp: _} -> false
                      _ -> true
                    end
                  end)

                case servers do
                  [] -> acc
                  servers -> [{name, servers} | acc]
                end
              end)
              |> Enum.each(fn {name, server_list} ->
                server_list
                |> Enum.each(fn server ->
                  AcariServer.Master.run_script_on_server(name, tag, server)
                end)
              end)

            scrtyp ->
              exec_nodes_list
              |> Enum.filter(fn %{name: name} ->
                with stat = %{} <- AcariServer.Mnesia.get_tunnel_state(name),
                     %{timestamp: ts, reqv_ts: reqv_ts} <- stat[tag] do
                  ts < reqv_ts
                else
                  _ ->
                    true
                end
              end)
              |> Enum.each(fn %{name: name} ->
                case scrtyp do
                  "zabbix" -> AcariServer.Zabbix.ZbxApi.zbx_exec_api(name, tag)
                  _ -> AcariServer.Master.exec_script_on_peer(name, tag)
                end
              end)
          end

          Process.sleep(1_000)
          get_script(socket, params["script_type"], tag, nodes_list)
        end

      "create_group" ->
        res =
          if socket.assigns.user.is_admin do
            descr =
              "#{get_group_name_by_id(params["group_id"])} \\ #{
                get_class_name_by_id(params["class_id"])
              } \\ #{params["filter"]}"

            case get_nodes_list(socket, params["group_id"], params["class_id"], params["filter"])
                 |> create_tmp_group(descr) do
              {:ok, group} ->
                Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "new_group.html",
                  group: group
                )

              {:error, res} ->
                "<h5 class=\"text-danger\">Ошибка при создании группы #{inspect(res)}</h5>"
            end
          else
            "<h5 class=\"text-danger\">Для создания группы нужны права администратора</h5>"
          end

        push(socket, "output", %{
          id: "new_group",
          data: res
        })

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_info({:output, id, data, opt}, socket) do
    push(socket, "output", %{id: id, data: data, opt: opt})
    {:noreply, socket}
  end

  defp get_nodes_list(socket, group_id, class_id, filter, opts \\ [])

  defp get_nodes_list(_socket, _group_id, _class_id, "false", _opts) do
    []
  end

  defp get_nodes_list(socket, group_id, class_id, filter, opts) do
    class_id =
      case class_id do
        "nil" -> nil
        nil -> nil
        id_str -> String.to_integer(id_str)
      end

    nodes =
      case group_id do
        "nil" ->
          AcariServer.NodeManager.list_nodes(socket.assigns[:user])

        "false" -> []

        group_id ->
          AcariServer.GroupManager.get_group!(group_id)
          |> Map.get(:nodes)
      end
      |> Enum.reject(fn %{lock: lock} -> lock end)

    case class_id do
      nil ->
        nodes

      class_id ->
        nodes |> Enum.filter(fn %{script_id: id} -> id == class_id end)
    end
    |> node_filter(filter, socket, opts)
  end

  defp get_exec_nodes_list(nodes_list, socket, tag) do
    user = socket.assigns.user
    template_rights = AcariServer.TemplateManager.get_template_by_name(tag).rights

    case user.is_admin or template_rights == "ro" do
      true ->
        nodes_list

      _ ->
        nodes_list
        |> Enum.filter(fn %{name: name} ->
          rights = user_rights(user, name)

          case AcariServer.UserManager.is_script_executable_for_user?(
                 template_rights,
                 rights
               ) do
            :ok -> true
            _ -> false
          end
        end)
    end
  end

  defp get_script(socket, script_type, tag, group_id, class_id, filter) do
    get_script(
      socket,
      script_type,
      tag,
      get_nodes_list(socket, group_id, class_id, filter)
    )
  end

  defp get_script(socket, "server", tag, nodes) do
    template_rights = AcariServer.TemplateManager.get_template_by_name(tag).rights
    user = socket.assigns.user

    script_res_list =
      nodes
      |> Enum.map(fn %{name: tun_name, description: descr} ->
        data =
          AcariServer.Mnesia.get_tunnel_srv_state(tun_name)[tag] ||
            %{}

        %{
          id: tun_name,
          description: descr,
          data: data,
          rights:
            if user.is_admin or template_rights == "ro" do
              true
            else
              rights = user_rights(user, tun_name)

              case AcariServer.UserManager.is_script_executable_for_user?(
                     template_rights,
                     rights
                   ) do
                :ok -> true
                _ -> false
              end
            end
        }
      end)

    push(socket, "output", %{
      id: "script",
      opt: AcariServer.NodeMonitor.get_templ_descr_by_name(tag) <> " (#{tag})",
      data:
        Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "oper_res_srv.html",
          script_res_list: script_res_list
        )
    })
  end

  defp get_script(socket, _script_type, tag, nodes) do
    template_rights = AcariServer.TemplateManager.get_template_by_name(tag).rights
    user = socket.assigns.user

    script_res_list =
      nodes
      |> Enum.map(fn %{id: id, name: tun_name, description: descr} ->
        {ts, data, reqv_ts} =
          case AcariServer.Mnesia.get_tunnel_state(tun_name)[tag] do
            %{timestamp: ts, data: data} = state -> {ts, data, state[:reqv_ts] || 0}
            state -> {0, "нет данных", state[:reqv_ts] || 0}
          end

        %{
          id: id,
          name: tun_name,
          description: descr,
          timestamp: ts,
          reqv_ts: reqv_ts,
          data: data |> to_string(),
          rights:
            if user.is_admin or template_rights == "ro" do
              true
            else
              rights = user_rights(user, tun_name)

              case AcariServer.UserManager.is_script_executable_for_user?(
                     template_rights,
                     rights
                   ) do
                :ok -> true
                _ -> false
              end
            end
        }
      end)

    push(socket, "output", %{
      id: "script",
      opt: AcariServer.NodeMonitor.get_templ_descr_by_name(tag) <> " (#{tag})",
      data:
        Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "oper_res.html",
          script_res_list: script_res_list,
          user_id: socket.assigns[:user]
        )
    })
  end

  defp user_rights(user, tun_name) do
    case user.is_admin do
      true ->
        "admin"

      _ ->
        AcariServer.UserManager.get_user_node_rights(
          user,
          AcariServer.NodeManager.get_node_by_name(tun_name).id
        )
    end
  end

  defp get_script_multi(socket, tag_list, group_id, class_id, filter) do
    script_res_multi =
      get_nodes_list(socket, group_id, class_id, filter)
      |> Enum.map(fn %{name: tun_name, description: descr} ->
        tag_data_list =
          (tag_list || [])
          |> Enum.map(fn tag ->
            case AcariServer.Mnesia.get_tunnel_state(tun_name)[tag] do
              %{data: data} -> {tag, data}
              _ -> {tag, "нет данных"}
            end
          end)

        %{id: tun_name, description: descr, data_list: tag_data_list}
      end)

    push(socket, "output", %{
      id: "script_multi",
      data:
        Phoenix.View.render_to_string(AcariServerWeb.GrpOperView, "oper_res_multi.html",
          script_res_multi: script_res_multi
        )
    })
  end

  defp get_class_list(nodes) do
    nodes
    |> Enum.reduce([], fn
      %{script_id: nil}, acc ->
        acc

      node, acc ->
        case Enum.find(acc, fn {id, _} -> id == node.script_id end) do
          nil -> [{node.script_id, AcariServer.ScriptManager.get_script!(node.script_id)} | acc]
          _ -> acc
        end
    end)
  end

  defp get_group_scripts(nodes, templ_group) do
    class_id_list = get_class_list(nodes)

    class_list =
      class_id_list
      |> Enum.map(fn
        nil ->
          {nil, MapSet.new()}

        {_, class} ->
          {{class.id, class.name},
           get_templates_list(class, templ_group)
           |> Enum.map(fn %{description: descr, name: name} -> {descr, name} end)
           |> MapSet.new()}
      end)

    common_script =
      class_list
      |> Enum.reduce(nil, fn
        {_, ms}, nil -> ms
        {_, ms}, acc -> MapSet.intersection(acc, ms)
      end)
      |> case(
        do:
          (
            nil -> []
            ms -> MapSet.to_list(ms)
          )
      )

    %{class_list: class_list, common_script: common_script}
  end

  defp get_templates_list(class, templ_group) do
    case templ_group do
      :zabbix ->
        AcariServer.TemplateManager.list_templates()
        |> Enum.filter(fn %{name: name} -> String.match?(name, ~r/\.zbx$/) end)

      _ ->
        case Map.get(class, templ_group) do
          res when is_list(res) -> res
          nil -> []
          res -> [res]
        end
    end
  end

  defp node_filter(node_list, filter_str, socket, opts \\ []) do
    filter_str = if to_string(filter_str) |> String.trim() == "", do: "true", else: filter_str

    push_filter_error(socket, "")

    enum_func =
      case opts[:filter_show] do
        true -> :map
        _ -> :filter
      end

    try do
      apply(Enum, enum_func, [
        node_list,
        fn node ->
          {_state, script} =
            (AcariServer.Mnesia.get_tunnel_state(node.name) || [])
            |> Enum.split_with(fn {k, _} -> is_atom(k) end)

          script =
            script
            |> Enum.map(fn
              {tag, %{data: data}} -> {tag, try_to_number(data)}
              x -> x
            end)

          lua_state =
            Sandbox.init()
            |> Sandbox.let_elixir_eval!("match", &match/2)
            |> Sandbox.let_elixir_eval!("vercmp", &vercmp/2)
            |> Sandbox.set!("script", script)
            |> Sandbox.set!(
              "client",
              node
              |> Map.from_struct()
              |> Enum.filter(fn
                {:name, _} -> true
                {:description, _} -> true
                {:params, _} -> true
                {:lock, _} -> true
                {:latitude, _} -> true
                {:longitude, _} -> true
                _ -> false
              end)
            )

          case Sandbox.eval(lua_state, "return (#{filter_str})") do
            {:ok, res} ->
              case opts[:filter_show] do
                true -> node |> Map.put(:filter_show, inspect(res, pretty: true))
                _ -> res
              end

            {:error, res} ->
              res = AcariServer.Template.humanize_lua_err(res)
              # case res do
              #   {:badmatch, {:error, [{_line, :luerl_parse, list}], []}} when is_list(list) ->
              #     Enum.join(list)
              #
              #   {:badmatch, {:error, [{_line, :luerl_scan, {a, s}}], []}} when is_atom(a) ->
              #     "#{a} #{inspect(s)}"
              #
              #   {:lua_error, {t, a, b}, _} when is_atom(t) ->
              #     "#{t} #{inspect(a)} #{inspect(b)}"
              #
              #   res ->
              #     inspect(res)
              # end

              raise(res)
          end
        end
      ])
    rescue
      e in RuntimeError ->
        push_filter_error(socket, e.message)
        node_list

      value ->
        push_filter_error(socket, inspect(value))
        node_list
    end
  end

  defp match(_, [str, pattern]) when is_binary(str) and is_binary(pattern) do
    Wild.match?(str, pattern)
  end

  defp match(_, _), do: false

  @regex_ver ~r/[\d\.]+/
  defp ver_to_list(ver) do
    with [ver] when is_binary(ver) <- Regex.run(@regex_ver, ver) do
      String.split(ver, ".")
      |> Enum.take_while(fn x -> x != "" end)
      |> Enum.map(fn x -> String.to_integer(x) end)
    else
      _ -> []
    end
  end

  defp vercmp(_, [ver1, ver2]) when is_binary(ver1) and is_binary(ver2) do
    v1 = ver_to_list(ver1)
    v2 = ver_to_list(ver2)

    cond do
      v1 > v2 -> "gt"
      v1 < v2 -> "lt"
      true -> "eq"
    end
  end

  defp vercmp(_, _), do: nil

  defp push_filter_error(socket, data) do
    push(socket, "output", %{
      id: "filter_error",
      data: data
    })
  end

  defp try_to_number(data) do
    str =
      data
      |> to_string()
      |> String.trim()

    case Integer.parse(str) do
      {n, ""} ->
        n

      _ ->
        case Float.parse(str) do
          {n, ""} -> n
          _ -> str
        end
    end
  end

  defp create_tmp_group(node_list, descr) do
    with grp_name <-
           "_TMP_" <> to_string(:os.system_time(:microsecond)),
         {:ok, group} <-
           AcariServer.GroupManager.create_group(%{
             name: grp_name,
             description: descr
           }) do
      node_list
      |> Enum.map(fn node ->
        AcariServer.GroupNodeAssociation.create_group_node(%{group_id: group.id, node_id: node.id})
      end)

      {:ok, group}
    else
      {:error, %{errors: res}} -> {:error, res}
      res -> {:error, res}
    end
  end

  defp get_group_name_by_id(id) do
    case id do
      "nil" -> "Все"
      id -> AcariServer.GroupManager.get_group_wo_nodes!(id).name
    end
  end

  defp get_class_name_by_id(id) do
    case id do
      "nil" -> "Все"
      id -> AcariServer.ScriptManager.get_script(id).name
    end
  end
end
