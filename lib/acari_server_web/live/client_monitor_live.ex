defmodule AcariServerWeb.ClientMonitorLive do
  use AcariServerWeb, :live_view
  require Logger

  @impl true
  def mount(%{"hash" => "test"}, _session, socket) do
    socket |> mount_client(AcariServer.NodeManager.get_node!(1))
  end

  def mount(%{"hash" => hash}, _session, socket) do
    socket |> mount_client(AcariServer.NodeManager.get_node_by_hash(hash))
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp mount_client(socket, %AcariServer.NodeManager.Node{} = node) do
    config_list = get_port_list_from_config(node)

    ports = ports_list(node, config_list)

    if connected?(socket) do
      Process.send_after(self(), :timer, 1000)
      Process.send_after(self(), :update, 10_000)
    end

    Phoenix.PubSub.subscribe(AcariServer.PubSub, "wizard:#{node.name}")
    Phoenix.PubSub.subscribe(AcariServer.PubSub, "link_state:#{node.name}")

    {:ok,
     assign(socket,
       node: node,
       ports: ports,
       config_list: config_list,
       local_time: AcariServer.get_local_time(:wo_date)
     )}
  end

  defp mount_client(socket, _) do
    {:ok, assign(socket, node: nil, ports: [])}
  end

  @impl true
  def handle_info({:timer, id}, socket) do
    send_update(AcariServerWeb.ClientMonitorLive.Radio, id: id, timer: true)
    {:noreply, socket}
  end

  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 1000)
    {:noreply, assign(socket, local_time: AcariServer.get_local_time(:wo_date))}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 10_000)
    update_ports(socket)
  end

  def handle_info({:wizard_trap, _key, _value}, socket) do
    update_ports(socket)
  end

  def handle_info({:update_link, _port, _server, _up}, socket) do
    update_ports(socket)
  end

  def handle_info(_mes, socket) do
    {:noreply, socket}
  end

  defp update_ports(socket) do
    ports = ports_list(socket.assigns.node, socket.assigns.config_list)

    new = ports -- socket.assigns.ports

    for name <- new do
      live_component(socket, AcariServerWeb.ClientMonitorLive.Radio,
        id: name,
        client_name: socket.assigns.node.name
      )
    end

    for name <- socket.assigns.ports do
      send_update(AcariServerWeb.ClientMonitorLive.Radio,
        id: name,
        client_name: socket.assigns.node.name
      )
    end

    node = AcariServer.NodeManager.get_node_rw!(socket.assigns.node.id)

    {:noreply, assign(socket, node: node, ports: ports)}
  end

  defp ports_list(node, config_list) do
    mnesia_list =
      AcariServer.Mnesia.get_link_list_for_tunnel(node.name)
      |> Enum.reduce([], fn %{name: name}, acc -> [name | acc] end)

    wizard_list =
      (AcariServer.Mnesia.get_tunnel_state(node.name)[:wizard] || [])
      |> Enum.reduce([], fn {key, _}, acc ->
        [AcariServerWeb.TunnelView.get_arg(key) | acc]
      end)

    (config_list ++ mnesia_list ++ wizard_list)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp get_port_list_from_config(node) do
    with %AcariServer.TemplateManager.Template{} = configure_template <-
           AcariServer.TemplateManager.get_template(node.script.remote_id),
         {:ok, {configure_script, _}} <-
           AcariServer.Template.test_eval(
             %{configure_template | test_client_name: node.name},
             %{}
           ),
         [_, acari_config_template_name] <-
           Regex.run(~r{cp\s+\./(.+)\s+/etc/acari/acari_config.exs}, configure_script),
         %AcariServer.TemplateManager.Template{} = acari_config_template <-
           AcariServer.TemplateManager.get_template_by_name(acari_config_template_name),
         {:ok, {acari_config_exs, _}} <-
           AcariServer.Template.test_eval(
             %{acari_config_template | test_client_name: node.name},
             %{}
           ),
         {:ok, acari_config} <- get_conf(acari_config_exs),
         links_list when is_list(links_list) <- acari_config[:links] do
      links_list
      |> Enum.map(fn kl -> kl[:dev] end)
      |> Enum.reject(&is_nil/1)
    else
      res ->
        Logger.warn("get_port_list_from_config: #{inspect(res)}")
        []
    end
  end

  defp get_conf(str) do
    try do
      {conf, _} = Code.eval_string(str)
      {:ok, conf}
    rescue
      x ->
        {:error, inspect(x)}
    end
  end
end
