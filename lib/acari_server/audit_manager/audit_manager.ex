defmodule AcariServer.AuditManager do
  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO
  alias AcariServer.AuditManager.Audit

  require Logger

  def list_audit_logs do
    RepoRO.all(Audit)
    |> localize()
  end

  def get_audit!(id) do
    RepoRO.get!(Audit, id)
    |> localize()
  end

  def create_audit(attrs \\ %{}) do
    %Audit{}
    |> Audit.changeset(attrs)
    |> Repo.insert()
  end

  def delete_audit(%Audit{} = audit) do
    Repo.delete(audit)
  end

  def change_audit(%Audit{} = audit) do
    Audit.changeset(audit, %{})
  end

  # audit_log functions

  @object_descr %{
    "class" => "Класс"
  }

  @operation_descr %{
    "create" => "Coздание",
    "update" => "Редактирование",
    "delete" => "Удаление"
  }

  def create_audit_log(conn, object, operation, params \\ %{})

  def create_audit_log(
        conn,
        %AcariServer.ScriptManager.Script{} = class,
        operation,
        params
      ) do
    create_audit(%{
      username: curr_user(conn),
      object: "class",
      object_name: class.name,
      operation: operation,
      params: params
    })

    conn
  end

  def create_audit_log(conn, object, _operation, _params) do
    Logger.error("Audit: #{curr_user(conn)}: unknown object #{inspect(object)}")
    conn
  end

  defp curr_user(conn) do
    conn.assigns.current_user.username
  end

  defp localize(list) when is_list(list) do
    list
    |> Enum.map(&localize/1)
  end

  defp localize(log) do
    %{
      log
      | object: @object_descr[log.object],
        operation: @operation_descr[log.operation],
        params:
          case log.params do
            params when is_map(params) ->
              params |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end) |> Enum.into(%{})

            params ->
              params
          end
    }
  end
end
