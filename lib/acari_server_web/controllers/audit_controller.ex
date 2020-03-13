defmodule AcariServerWeb.AuditController do
  use AcariServerWeb, :controller

  alias AcariServer.AuditManager
  alias AcariServer.AuditManager.Audit

  def index(conn, _params) do
    audit_logs = AuditManager.list_audit_logs()
    render(conn, "index.html", audit_logs: audit_logs)
  end

  def new(conn, _params) do
    changeset = AuditManager.change_audit(%Audit{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"audit" => audit_params}) do
    case AuditManager.create_audit(audit_params) do
      {:ok, audit} ->
        conn
        |> put_flash(:info, "Audit created successfully.")
        |> redirect(to: Routes.audit_path(conn, :show, audit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    audit = AuditManager.get_audit!(id)
    render(conn, "show.html", audit: audit)
  end

  def edit(conn, %{"id" => id}) do
    audit = AuditManager.get_audit!(id)
    changeset = AuditManager.change_audit(audit)
    render(conn, "edit.html", audit: audit, changeset: changeset)
  end

  def update(conn, %{"id" => id, "audit" => audit_params}) do
    audit = AuditManager.get_audit!(id)

    case AuditManager.update_audit(audit, audit_params) do
      {:ok, audit} ->
        conn
        |> put_flash(:info, "Audit updated successfully.")
        |> redirect(to: Routes.audit_path(conn, :show, audit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", audit: audit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    audit = AuditManager.get_audit!(id)
    {:ok, _audit} = AuditManager.delete_audit(audit)

    conn
    |> put_flash(:info, "Audit deleted successfully.")
    |> redirect(to: Routes.audit_path(conn, :index))
  end
end
