defmodule AcariServer.Zabbix.LastDataAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  # API
  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def get(host) do
    Agent.get(__MODULE__, fn state -> state[host] end)
  end

  def get(host, sensor) do
    Agent.get(__MODULE__, fn state -> state[host][sensor] end)
  end

  def put(host, key, value) do
    Agent.update(
      __MODULE__,
      fn state ->
        put_aux(state, host, key, value)
      end
    )
  end

  def clean() do
    Agent.update(
      __MODULE__,
      fn _state ->
        %{}
      end
    )
  end

  def clean(host) do
    Agent.update(
      __MODULE__,
      fn state ->
        state |> Map.delete(host)
      end
    )
  end

  defp put_aux(state, host, key, value) do
    case state[host] do
      nil -> state |> Map.put(host, %{}) |> put_aux(host, key, value)
      _ -> put_in(state, [host, key], {value, :erlang.system_time(:second)})
    end
  end
end
