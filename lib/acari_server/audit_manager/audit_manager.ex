defmodule AcariServer.AuditManager do
  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO
  alias AcariServer.AuditManager.Audit

  require Logger

  def list_audit_logs do
    RepoRO.all(Audit)
    |> humanize()
  end

  def get_audit!(id) do
    RepoRO.get!(Audit, id)
    |> humanize()
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

  @name_descr %{
    "update" => "Редактирование",
    "class" => "Класс"
  }

  def create_audit_log(conn, object, operation)

  def create_audit_log(
        conn,
        %AcariServer.ScriptManager.Script{} = class,
        operation
      ) do
    create_audit(%{
      username: curr_user(conn),
      object: "class",
      object_name: class.name,
      operation: operation,
      params: %{
        "description" => class.description,
        "remote" => class.remote && class.remote.description,
        "local" => class.local && class.local.description,
        "templates" => AcariServerWeb.ScriptView.templates_list(class),
        "definition" => class.definition,
        "prefix" => class.prefix,
        "test_client_name" => class.test_client_name
      }
    })

    conn
  end

  def create_audit_log(conn, object, _operation) do
    Logger.error("Audit: #{curr_user(conn)}: unknown object #{inspect(object)}")
    conn
  end

  defp curr_user(conn) do
    conn.assigns.current_user.username
  end

  defp humanize(list) when is_list(list) do
    list
    |> Enum.map(&humanize/1)
  end

  defp humanize(log) do
    %{
      log
      | object: @name_descr[log.object],
        operation: @name_descr[log.operation],
        params: humanize(log.object, log.params)
    }
  end

  defp humanize("class", params) do
    """
    Описание: #{params["description"]},
    Конфигурация клиента: #{params["remote"]},
    Конфигурация сервера: #{params["local"]},
    Скрипты:
      #{params["templates"]},
    Определения параметров:
      #{params["definition"]},
    Вычисление параметров:
      #{params["prefix"]},
    Тестовый клиент: #{params["test_client_name"]}
    """
  end
end
