defmodule AcariServerWeb.TemplateController do
  use AcariServerWeb, :controller

  alias AcariServer.TemplateManager
  alias AcariServer.TemplateManager.Template
  alias AcariServer.TemplateEventManager
  alias AcariServer.AuditManager

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new]

  def index(conn, _params) do
    templates = TemplateManager.list_templates()
    render(conn, "index.html", templates: templates)
  end

  def new(conn, %{"template_id" => id}) do
    template = TemplateManager.get_template!(id)

    changeset = TemplateManager.change_template(template |> Ecto.put_meta(state: :built))

    render(conn, "new.html", changeset: changeset, template: template)
  end

  def new(conn, _params) do
    changeset = TemplateManager.change_template(%Template{})
    render(conn, "new.html", changeset: changeset)
  end

  defp create_template_event(conn, template_params, template) do
    if template_params["template"] != template.template do
      TemplateEventManager.create_template_event(%{
        username: conn.assigns.current_user.username,
        template_name: template_params["name"],
        description: template_params["description"],
        template: template_params["template"]
      })
    end

    conn
  end

  def create(conn, %{"template" => template_params}) do
    case TemplateManager.create_template(template_params) do
      {:ok, template} ->
        conn
        |> AuditManager.create_audit_log(template, "create", template_params)
        |> put_flash(:info, "Шаблон создан.")
        |> redirect(to: Routes.template_path(conn, :show, template))
        |> create_template_event(template_params, %{template: ""})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    template = TemplateManager.get_template!(id)
    render(conn, "show.html", template: template)
  end

  def edit(conn, %{"id" => id}) do
    template = TemplateManager.get_template!(id)
    changeset = TemplateManager.change_template(template)
    render(conn, "edit.html", template: template, changeset: changeset)
  end

  def update(conn, %{"id" => id, "template" => template_params}) do
    template = TemplateManager.get_template!(id)

    case TemplateManager.update_template(template, template_params) do
      {:ok, templ} ->
        conn
        |> AuditManager.create_audit_log(template, "update", template_params)
        |> put_flash(:info, "Шаблон отредактирован.")
        |> redirect(to: Routes.template_path(conn, :show, templ))
        |> create_template_event(template_params, template)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", template: template, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    template = TemplateManager.get_template!(id)
    {:ok, _template} = TemplateManager.delete_template(template)

    conn
    |> AuditManager.create_audit_log(template, "delete")
    |> put_flash(:info, "Шаблон удален.")
    |> redirect(to: Routes.template_path(conn, :index))
  end

  def diff(conn, %{"id" => id}) do
    template = TemplateManager.get_template!(id)
    diff = AcariServer.TemplateEventManager.get_template_events_diff(template.name)
    render(conn, "diff.html", template: template, diff: diff)
  end
end
