defmodule AcariServerWeb.QRPrintLive do
  use AcariServerWeb, :live_view

  @impl true
  def mount(params, %{"clients_list" => ids} = session, socket) do
    IO.inspect(params: params, session: session)

    qr_list =
      String.split(ids, ",")
      |> IO.inspect()

    {:ok,
     assign(socket,
       qr_list: qr_list,
       qr_num: length(qr_list),
       top: "15",
       bottom: "15",
       left: "15",
       right: "15",
       gap: "1",
       cols: "3",
       rows: "8"
     )}
  end

  @impl true
  def handle_event("draw", params, socket) do
    IO.inspect(params: params)

    {:noreply,
     assign(socket,
       top: params["top"],
       bottom: params["bottom"],
       left: params["left"],
       right: params["right"],
       gap: params["gap"],
       cols: params["cols"],
       rows: params["rows"]
     )}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp get_gap(gap) do
    IO.inspect(gap)

    case Float.parse(gap) do
      {n, _} -> n / 2
      _ -> 0.5
    end
  end
end
