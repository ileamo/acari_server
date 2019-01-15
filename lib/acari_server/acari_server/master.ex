defmodule AcariServer.Master do
  use GenServer
  require Logger

  defmodule State do
    defstruct [
      :tuns
    ]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ## Callbacks
  @impl true
  def init(_params) do
    tuns = :ets.new(:tuns, [:set, :protected, :named_table])

    {:ok, %State{tuns: tuns}}
  end

  @impl true

  def handle_cast({:tun_started, %{tun_name: tun_name} = tun_state}, state) do
    Logger.debug("Master get :tun_started from #{tun_name}, tun_state = #{inspect(tun_state)}")
    params = %{"ifname" => tun_state.ifname}
    peer_params = tun_state.peer_params
    :ets.insert(:tuns, {tun_name, params, peer_params})
    exec_local_script(tun_name, params, peer_params)

    # Acari.ip_address(:add, tun_name, %{"prefix" => "192.168.1.1/32", "peer" => "192.168.1.2"})
    {:noreply, state}
  end

  def handle_cast({:peer_started, tun_name}, state) do
    Logger.debug("Master get :peer_started from #{tun_name}")
    [{_, params, peer_params}] = :ets.lookup(:tuns, tun_name)
    exec_remote_script(tun_name, params, peer_params)

    {:noreply, state}
  end

  def handle_cast(mes, state) do
    Logger.warn("Master get unknown message: #{inspect(mes)}")
    {:noreply, state}
  end

  defp exec_local_script(tun_name, params, peer_params) do
    with %{script: %{local: templ}} <- AcariServer.NodeManager.get_node_with_script(tun_name),
         assigns <-
           peer_params
           |> Enum.map(fn {k, v} -> {"peer_" <> k, v} end)
           |> Enum.concat(Map.to_list(params))
           |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
           |> List.insert_at(0, {:id, tun_name})
           |> Enum.into(%{}),
         {script, nil} <- AcariServer.Template.eval(templ, assigns) do
      Acari.exec_sh(script)
    else
      res -> Logger.error("Can't exec local script: #{inspect(res)}")
    end
  end

  defp exec_remote_script(tun_name, params, peer_params) do
    IO.inspect({tun_name, params, peer_params}, label: "EXEC_REMOTE_SCRIPT")
  end
end
