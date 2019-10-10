defmodule AcariServer.NodeMonitor do
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  @impl true
  def init(%{output_pid: output_pid, pathname: pathname} = _params) do
    [_, name] = Regex.run(~r|/([^/]+)$|, pathname)

    {:ok,
     %{
       tun_name: name,
       output_pid: output_pid
     }}
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
        put_data(
          self(),
          "script",
          script_to_string(
            params["script"],
            AcariServer.Mnesia.get_tunnel_state(tun_name)[params["script"]]
          ),
          get_templ_descr_by_name(params["script"])
        )

      "script" ->
        with tag when is_binary(tag) <- params["script"] do
          AcariServer.NodeMonitorAgent.callback(self(), tun_name, tag)
          AcariServer.Master.exec_script_on_peer(tun_name, tag)
        else
          _ ->
            script_not_defined("script")
        end

      "srv_script" ->
        with tag when is_binary(tag) <- params["script"] do
          # AcariServer.NodeMonitorAgent.callback(self(), tun_name, tag)
          AcariServer.Master.run_script_on_all_servers(tun_name, tag)
        else
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
  defp script_not_defined(id) do
    put_data(
      self(),
      id,
      "                            ^\n" <>
        "Выберите скрипт из меню ----|",
      "Скрипт не определен"
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
        "#{AcariServer.get_local_time(ts)}  #{id}\n\n#{data}"

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
        |> List.insert_at(0, id<>"\n")
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
