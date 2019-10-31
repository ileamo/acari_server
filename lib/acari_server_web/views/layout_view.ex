defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  def get_mes() do
    current_time = :os.system_time(:microsecond)

    AcariServer.Mnesia.get_event_list()
    |> Enum.sort_by(fn %{count: c} -> c end, &>/2)
    #|> Enum.uniq_by(fn %{header: hd} -> hd end)
    |> Enum.map(fn %{level: lv, header: hd, text: body, timestamp: ts} ->
      alert =
        case lv do
          1 -> "danger"
          2 -> "warning"
          3 -> "info"
          4 -> ""
          _ -> "secondary"
        end

      {alert, "#{get_local_time(ts, current_time)} #{hd}", body}
    end)
  end

  defp get_local_time(system_time, current_time) do
    {{y, mn, d}, {h, m, s}} = :calendar.system_time_to_local_time(system_time, :microsecond)

    case current_time - system_time > 1_000_000 * 60 * 60 * 24 do
      true ->
        :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [y, mn, d, h, m, s])

      _ ->
        :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
    end
  end
end
