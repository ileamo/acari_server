defmodule AcariServer.NodeMonitorAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # API

  def callback(pid, tun_name, id) do
    Agent.update(
      __MODULE__,
      fn state ->
        [{pid, tun_name, id} | state]
      end
    )
  end

  def event(tun_name, id, data) do
    [node() | Node.list()]
    |> Enum.each(fn node ->
      Agent.update(
        {__MODULE__, node},
        __MODULE__,
        :push_data,
        [tun_name, id, data]
      )
    end)
  end

  def push_data(state, tun_name, id, data) do
    state
    |> Enum.reject(fn
      {pid, ^tun_name, ^id} ->
        AcariServer.NodeMonitor.put_data(pid, id, data)
        true

      {pid, _, _} ->
        if Process.alive?(pid), do: false, else: true
    end)
  end
end
