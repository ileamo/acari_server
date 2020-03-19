defmodule AcariServer.AuditManager do
  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO
  alias AcariServer.AuditManager.Audit

  require Logger

  def list_audit_logs do
    Audit
    |> order_by(desc: :inserted_at, desc: :id)
    |> limit(1000)
    |> RepoRO.all()
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
    "class" => "Класс",
    "client" => "Клиент",
    "clients" => "Клиенты",
    "server" => "Сервер",
    "group" => "Группа",
    "schedule" => "Планировщик",
    "template" => "Шаблон",
    "auth" => "Аутентификация",
  }

  @operation_descr %{
    "create" => "Coздание",
    "update" => "Редактирование",
    "delete" => "Удаление",
    "lock" => "Блокирование",
    "unlock" => "Разблокирование",
    "class" => "Изменение класса",
    "groups" => "Изменение групп  ",
    "login" => "Вход",
    "logout" => "Выход",
    "logerr" => "Неудачный вход",
    "client_script" => "Выполнение скрипта",
    "server_script" => "Выполнение скрипта на сервере"
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

  defp parse_object({:tunnel, tun_name}) do
    %{
      object: "client",
      object_name: tun_name
    }
  end

  defp parse_object(:tunnels) do
    %{
      object: "clients",
      object_name: "Группа"
    }
  end

  defp parse_object("clients") do
    %{
      object: "clients",
      object_name: "Группа"
    }
  end

  defp parse_object({"auth", name}) do
    %{
      object: "auth",
      object_name: name,
      username: name
    }
  end

  defp parse_object(%AcariServer.ScriptManager.Script{} = class) do
    %{
      object: "class",
      object_name: class.name
    }
  end

  defp parse_object(%AcariServer.NodeManager.Node{} = client) do
    %{
      object: "client",
      object_name: client.name
    }
  end

  defp parse_object(%AcariServer.UserManager.User{} = user) do
    %{
      object: "user",
      object_name: user.username
    }
  end

  defp parse_object(%AcariServer.ServerManager.Server{} = server) do
    %{
      object: "server",
      object_name: server.name
    }
  end

  defp parse_object(%AcariServer.GroupManager.Group{} = group) do
    %{
      object: "group",
      object_name: group.name
    }
  end

  defp parse_object(%AcariServer.ScheduleManager.Schedule{} = schedule) do
    %{
      object: "schedule",
      object_name: schedule.description
    }
  end

  defp parse_object(%AcariServer.TemplateManager.Template{} = template) do
    %{
      object: "template",
      object_name: template.name
    }
  end

  defp parse_object(_) do
    %{
      object: "<UNKNOWN>",
      object_name: "<UNKNOWN>"
    }
  end

  defp curr_user(%Plug.Conn{assigns: %{current_user: %{username: name}}}) do
    name
  end

  defp curr_user(%Phoenix.Socket{assigns: %{user: %{username: name}}}) do
    name
  end

  defp curr_user(%{username: name}) do
    name
  end

  defp curr_user(a) do
    "unknown"
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
