defmodule AcariServer.Zabbix.Handler do
  use GenServer
  require Logger
  alias AcariServer.Zabbix.Handler.Internal

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:handle, host, key, value}, state) do
    with {handler, key} when handler != "" <- parse_key(key) do
      with func when is_atom(func) <- to_atom(handler),
           true <- function_exported?(Internal, func, 3) do
        apply(Internal, func, [host, key, value])
      else
        # TODO script callback
        _ -> Logger.warn("Zabbix handler: Unknown handler #{handler}")
      end
    else
      _ -> Logger.warn("Zabbix handler: Unknown key #{key}")
    end

    {:noreply, state}
  end

  def wizard_clear_port(host, port) do
    with %{} = map <- AcariServer.Mnesia.get_tunnel_state(host)[:wizard],
         %{^port => sens} <-
           Enum.group_by(map, fn {key, _} -> AcariServerWeb.TunnelView.get_arg(key) end) do
      sens =
        sens
        |> Enum.map(fn {key, _} -> {key, nil} end)
        |> Enum.into(%{})

      AcariServer.Mnesia.update_tun_state(host, :wizard, sens)
    end
  end

  # API
  def handle(host, key, value) do
    GenServer.cast(__MODULE__, {:handle, host, key, value})
  end

  # Private func
  defp parse_key(key) do
    case Regex.run(~r/^([a-zA-Z0-9_]+)\.(.*)$/, key) do
      [_, handler, key] -> {handler, key}
      _ -> nil
    end
  end

  defp to_atom(str) do
    try do
      String.to_existing_atom(str)
    rescue
      _ -> 0
    end
  end
end

defmodule AcariServer.Zabbix.Handler.Internal do
  require Logger

  def wizard(host, key, value) do
    AcariServer.Mnesia.update_tun_state(host, :wizard, %{
      key => %{value: value, timestamp: :os.system_time(:second)}
    })

    Phoenix.PubSub.broadcast(
      AcariServer.PubSub,
      "wizard:#{host}",
      {:wizard_trap, key, value}
    )
  end

  def system(host, "restarted", _value) do
    ts = :os.system_time(:second)
    init = %{num: 1, list: [ts]}

    AcariServer.Mnesia.update_tun_state(
      host,
      :client_restarts,
      init,
      merge: fn old_data, _ ->
        case old_data do
          %{list: list} ->
            new_list = [ts | list |> Enum.reject(fn x -> ts - x >= 60 * 60 * 24 end)]
            num = length(new_list)
            %{old_data | list: new_list, num: num}

          _ ->
            init
        end
      end
    )
  end

  def system(_host, key, _value) do
    Logger.warn("Zabbix handler: Unknown key '#{key}' for handler 'system'")
  end
end
