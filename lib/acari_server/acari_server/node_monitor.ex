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
    IO.inspect(params, label: "MONITOR")

    case id do
      "inventory" ->
        AcariServer.Master.get_inventory(tun_name)

      "telemetry" ->
        AcariServer.Master.get_telemetry(tun_name)

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
          AcariServer.Mnesia.get_tunnel_state(tun_name)[params["script"]] || "Нет данных",
          params["script"]
        )

      "script" ->
        tag = params["script"]
        AcariServer.NodeMonitorAgent.callback(self(), tun_name, tag)
        AcariServer.Master.exec_script_on_peer(tun_name, tag)

      _ ->
        nil
    end

    {:noreply, state}
  end

  def handle_cast({:output, id, data, opt}, %{output_pid: output_pid} = state) do
    IO.inspect({id, data}, label: "OUTPUT")
    send(output_pid, {:output, id, data, opt})
    {:noreply, state}
  end

  # API
  def get_input(node_monitor, input) do
    GenServer.cast(node_monitor, {:input, input})
  end

  def put_data(node_monitor, id, data, opt \\ nil) do
    GenServer.cast(node_monitor, {:output, id, data, opt})
  end
end
