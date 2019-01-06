defmodule Acari.LinkEventAgent do
  use Agent

  @max_items 50

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  defp put(item) do
    Agent.update(
      __MODULE__,
      fn state ->
        [item | state]
        |> Enum.take(@max_items)
      end
    )
  end

  defp remove(tun, link) do
    Agent.update(
      __MODULE__,
      fn state ->
        state
        |> Enum.reject(fn
          {^tun, ^link, _} -> true
          {^tun, nil, _} -> true
          _ -> false
        end)
      end
    )
  end

  def event(:open, tun, link) do
    remove(tun, link)
  end

  def event(:close, _, nil, _) do
  end

  def event(:close, tun, link, num) do
    timestamp = get_local_time()
    put({tun, link, timestamp})

    if num == 0 do
      put({tun, nil, timestamp})
    end
  end

  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  defp get_local_time() do
    {_, {h, m, s}} = :calendar.local_time()
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
  end
end
