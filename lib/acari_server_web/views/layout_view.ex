defmodule AcariServerWeb.LayoutView do
  use AcariServerWeb, :view

  def username(conn) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || "Anonymous"
  end

  def get_local_time(system_time, current_time) do
    {{y, mn, d}, {h, m, s}} = :calendar.system_time_to_local_time(system_time, :microsecond)

    case current_time - system_time > 1_000_000 * 60 * 60 * 24 do
      true ->
        :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [y, mn, d, h, m, s])

      _ ->
        :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s])
    end
  end
end
