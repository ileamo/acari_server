defmodule AcariServer.NodeMonitorAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # API

  def callback(pid, tun_name, id, script_type) do
    Agent.update(
      __MODULE__,
      fn state ->
        [{pid, tun_name, id, script_type} | state]
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
      {pid, ^tun_name, ^id, script_type} ->
        AcariServer.NodeMonitor.put_data(
          pid,
          script_type,
          AcariServer.NodeMonitor.script_to_string(id, data),
          AcariServer.TemplateManager.get_template_by_name(id).description
        )

        true

      {pid, _, _, _} ->
        if Process.alive?(pid), do: false, else: true
    end)
  end
end
