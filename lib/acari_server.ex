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
end
