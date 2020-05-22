defmodule AcariServerWeb.ScriptController do
  use AcariServerWeb, :controller

  alias AcariServer.ScriptManager
  alias AcariServer.ScriptManager.Script
  alias AcariServer.AuditManager

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new]

  def index(conn, _params) do
    scripts = ScriptManager.list_scripts()
    render(conn, "index.html", scripts: scripts)
  end

  def new(conn, %{"script_id" => id}) do
    script = ScriptManager.get_script!(id)

    changeset = ScriptManager.change_script(script |> Ecto.put_meta(state: :built))
    render(conn, "new.html", script: script, changeset: changeset)
  end

  def new(conn, _) do
    changeset = ScriptManager.change_script(%Script{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"script" => script_params}) do
    case ScriptManager.create_script(script_params) do
      {:ok, script} ->
        conn
        |> put_flash(:info, "Класс создан.")
        |> redirect(to: Routes.script_path(conn, :show, script))
        |> AuditManager.create_audit_log(script, "create", script_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    script = ScriptManager.get_script!(id)
    render(conn, "show.html", script: script)
  end

  def edit(conn, %{"id" => id}) do
    script = ScriptManager.get_script!(id)
    changeset = ScriptManager.change_script(script)
    render(conn, "edit.html", script: script, changeset: changeset)
  end

  def update(conn, %{"id" => id, "script" => script_params}) do
    script = ScriptManager.get_script!(id)
    old_definition = script.definition

    case ScriptManager.update_script(script, script_params) do
      {:ok, script} ->
        if script.definition != old_definition do
          with {old, nil} <- AcariServer.Template.get_json(old_definition),
               {new, nil} <- AcariServer.Template.get_json(script.definition),
               false <- Map.equal?(old, new) do
            var_def = AcariServer.Template.normalize_vars(new)

            script
            |> AcariServer.ScriptManager.get_clients_of_class()
            |> Enum.each(fn client ->
              update_client_params(script.id, client, var_def)
            end)
          end
        end

        conn
        |> put_flash(:info, "Класс отредактирован.")
        |> redirect(to: Routes.script_path(conn, :show, script))
        |> AuditManager.create_audit_log(script, "update", script_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", script: script, changeset: changeset)
    end
  end

  defp update_client_params(script_id, client, var_def) do
    client
    |> AcariServer.RepoRO.preload(:groups)
    |> AcariServer.NodeManager.update_node(
      %{"script_id" => to_string(script_id), "groups_list" => false},
      var_def: var_def
    )
  end

  def delete(conn, %{"id" => id}) do
    script = ScriptManager.get_script!(id)
    {:ok, _script} = ScriptManager.delete_script(script)

    conn
    |> AuditManager.create_audit_log(script, "delete")
    |> put_flash(:info, "Класс удален.")
    |> redirect(to: Routes.script_path(conn, :index))
  end
end
