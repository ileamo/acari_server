defmodule AcariServer.NodeMonitor do
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  @impl true
  def init(params) do
    {:ok, params}
  end

  @impl true
  def handle_cast({:input, %{"input" => id} = params}, %{tun_name: tun_name} = state) do
    case id do
      "links_state" ->
        links_state = AcariServer.Mnesia.get_link_list_for_tunnel(tun_name)

        ls_html =
          Phoenix.View.render_to_string(AcariServerWeb.TunnelView, "links_state.html",
            links_state: links_state
          )

        put_data(self(), "links_state", ls_html)

      "sensors" ->
        put_data(self(), "sensors", AcariServerWeb.TunnelView.get_sensors_html(:string, tun_name))

      "get_script" ->
        handle_get_script(tun_name, params["script"], "script")

      "get_zbx_script" ->
        handle_get_script(tun_name, params["script"], "zbx_script")

      "script" ->
        handle_script(state, tun_name, params["script"], "script")

      "zbx_script" ->
        handle_script(state, tun_name, params["script"], "zbx_script")

      "srv_script" ->
        with tag when is_binary(tag) <- params["script"],
             %AcariServer.TemplateManager.Template{} = template <-
               AcariServer.TemplateManager.get_template_by_name(tag),
             :ok <-
               AcariServer.UserManager.is_script_executable_for_user?(
                 template.rights,
                 state.rights
               ) do
          AcariServer.Master.run_script_on_all_servers(tun_name, tag)

          AcariServer.AuditManager.create_audit_log(
            state,
            {:tunnel, tun_name},
            "server_script",
            %{"template_name" => tag}
          )
        else
          :no_rights ->
            no_rights_for_script("srv_script", params["script"])

          _ ->
            script_not_defined("srv_script")
        end

      "get_srv_script" ->
        put_data(
          self(),
          "srv_script",
          srv_script_to_string(
            params["script"],
            AcariServer.Mnesia.get_tunnel_srv_state(tun_name)[params["script"]]
          ),
          get_templ_descr_by_name(params["script"])
        )

      _ ->
        nil
    end

    {:noreply, state}
  end

  def handle_cast({:output, id, data, opt}, %{output_pid: output_pid} = state) do
    send(output_pid, {:output, id, data, opt})
    {:noreply, state}
  end

  # functions

  defp handle_get_script(tun_name, script_name, script_type) do
    put_data(
      self(),
      script_type,
      script_to_string(
        script_name,
        AcariServer.Mnesia.get_tunnel_state(tun_name)[script_name]
      ),
      get_templ_descr_by_name(script_name)
    )
  end

  defp handle_script(state, tun_name, script_name, script_type) do
    with tag when is_binary(tag) <- script_name,
         %AcariServer.TemplateManager.Template{} = template <-
           AcariServer.TemplateManager.get_template_by_name(tag),
         :ok <-
           AcariServer.UserManager.is_script_executable_for_user?(
             template.rights,
             state.rights
           ) do
      AcariServer.NodeMonitorAgent.callback(self(), tun_name, tag, script_type)

      case script_type do
        "zbx_script" -> AcariServer.Zabbix.ZbxApi.zbx_exec_api(tun_name, tag)
        _ -> AcariServer.Master.exec_script_on_peer(tun_name, tag)
      end

      AcariServer.AuditManager.create_audit_log(
        state,
        {:tunnel, tun_name},
        "client_script",
        %{"template_name" => tag}
      )
    else
      :no_rights ->
        no_rights_for_script(script_type, script_name)

      _ ->
        script_not_defined(script_type)
    end
  end

  defp script_not_defined(id) do
    put_data(
      self(),
      id,
      "                            ^\n" <>
        "Выберите скрипт из меню ----|",
      "Скрипт не определен"
    )
  end

  defp no_rights_for_script(id, tag) do
    put_data(
      self(),
      id,
      "У Вас нет прав на выполнение этого скрипта",
      get_templ_descr_by_name(tag)
    )
  end

  def get_templ_descr_by_name(name) do
    with %AcariServer.TemplateManager.Template{description: descr} <-
           AcariServer.TemplateManager.get_template_by_name(name |> to_string()) do
      descr || "_#{name}_"
    else
      _ -> "Скрипт не определен"
    end
  end

  def script_to_string(id, data) do
    case data do
      %{timestamp: ts, data: data} ->
        "#{AcariServer.get_local_date(ts)}  #{id}\n\n#{data}"

      _ ->
        "Нет данных"
    end
  end

  defp srv_script_to_string(id, data) do
    case data do
      %{} = data_map ->
        data_map
        |> Enum.map(fn {node_name, %{timestamp: ts, data: data}} ->
          "#{AcariServer.get_local_time(ts)}  #{node_name}\n#{data}"
        end)
        |> List.insert_at(0, (id || "unknown") <> "\n")
        |> Enum.join("\n")

      _ ->
        "Нет данных"
    end
  end

  # API
  def get_input(node_monitor, input) do
    GenServer.cast(node_monitor, {:input, input})
  end

  def put_data(node_monitor, id, data, opt \\ nil) do
    GenServer.cast(node_monitor, {:output, id, data, opt})
  end
end
