defmodule Acari.LinkEventAgent do
  use Agent
  alias AcariServerWeb.Endpoint

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

  def event(:open, tun, link) when binary_part(tun, 0, 2) != "cl" do
    remove(tun, link)
    broadcast_link_event()
  end

  def event(:close, tun, link, num) when binary_part(tun, 0, 2) != "cl" do
    timestamp = get_local_time()
    put({tun, link, timestamp})

    if num == 0 do
      put({tun, nil, timestamp})
    end

    broadcast_link_event()
  end

  def event(_, _, _, _ \\ nil) do
  end

  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def get_length() do
    Agent.get(__MODULE__, fn state -> length(state) end)
  end

  defp get_local_time() do
    {_, {h, m, s}} = :calendar.local_time()
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
  end

  defp broadcast_link_event() do
    mes_html = Phoenix.View.render_to_string(AcariServerWeb.LayoutView, "messages.html", [])

    Endpoint.broadcast!("room:lobby", "link_event", %{
      num_of_mes: get_length(),
      messages: mes_html
    })
  end
end
