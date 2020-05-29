defmodule AcariServer.Zabbix.Handler do
  use GenServer
  require Logger

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
           true <- function_exported?(__MODULE__, func, 3) do
        apply(__MODULE__, func, [host, key, value])
      else
        # TODO script callback
        _ -> nil
      end
    else
      _ -> Logger.warn("Zabbix handler: Unknown key #{key}")
    end

    {:noreply, state}
  end

  # Internal handlers
  def wizard(host, key, value) do
    AcariServer.Mnesia.update_tun_state(host, :wizard, %{
      key => %{value: value, timestamp: :os.system_time(:second)}
    })


  end

  # API
  def handle(host, key, value) do
    GenServer.cast(__MODULE__, {:handle, host, key, value})
  end

  # Private func
  defp parse_key(key) do
    case Regex.run(~r/^([a-zA-Z0-9_\-]+).(.*)$/, key) do
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
