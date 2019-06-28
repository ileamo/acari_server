defmodule AcariServer do
  @moduledoc """
  AcariServer keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def db_time_to_local(time) do
    time
    |> NaiveDateTime.to_erl()
    |> :erlang.universaltime_to_localtime()
    |> NaiveDateTime.from_erl()
    |> (fn {:ok, tm} -> NaiveDateTime.to_string(tm) end).()
  end

  def get_local_time() do
    {{y, mn, d}, {h, m, s}} = :calendar.local_time()
    :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [y, mn, d, h, m, s])
  end

  def get_local_time(system_time) do
    {{y, mn, d}, {h, m, s}} = :calendar.system_time_to_local_time(system_time, :second)
    :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [y, mn, d, h, m, s])
  end

end
