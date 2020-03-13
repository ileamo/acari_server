defmodule AcariServerWeb.AuditController do
  use AcariServerWeb, :controller

  alias AcariServer.AuditManager
  alias AcariServer.AuditManager.Audit

  def index(conn, _params) do
    audit_logs = AuditManager.list_audit_logs()
    render(conn, "index.html", audit_logs: audit_logs)
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

end
