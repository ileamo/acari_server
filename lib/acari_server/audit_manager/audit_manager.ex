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
    "user" => "Пользователь",
    "class" => "Класс"
  }

  @operation_descr %{
    "create" => "Coздание",
    "update" => "Редактирование",
    "delete" => "Удаление"
  }

  def create_audit_log(conn, object, operation, params \\ %{}) do
    %{
      username: curr_user(conn),
      operation: operation,
      params: params
    }
    |> Map.merge(parse_object(object))
    |> create_audit()

    conn
  end

  defp parse_object(%AcariServer.ScriptManager.Script{} = class) do
    %{
      object: "class",
      object_name: class.name
    }
  end

  defp parse_object(%AcariServer.UserManager.User{} = user) do
    %{
      object: "user",
      object_name: user.username
    }
  end


  defp parse_object(_) do
    %{
      object: "<UNKNOWN>",
      object_name: "<UNKNOWN>"
    }
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
