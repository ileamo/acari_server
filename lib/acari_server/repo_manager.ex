defmodule AcariServer.RepoManager do
  alias Ecto.Adapters.SQL

  def pg_is_in_recovery(repo) do
    case SQL.query(repo, "select pg_is_in_recovery();", []) do
      {:ok, %Postgrex.Result{rows: [[res]]}} -> res
      _ -> nil
    end
  end
end
