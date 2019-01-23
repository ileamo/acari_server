defmodule AcariServerWeb.TemplateController do
  use AcariServerWeb, :controller

  alias AcariServer.TemplateManager
  alias AcariServer.TemplateManager.Template

  def index(conn, _params) do
    templates = TemplateManager.list_templates()
    render(conn, "index.html", templates: templates)
  end

  def new(conn, _params) do
    changeset = TemplateManager.change_template(%Template{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"template" => template_params}) do
    case TemplateManager.create_template(template_params) do
      {:ok, template} ->
        conn
        |> put_flash(:info, "Template created successfully.")
        |> redirect(to: Routes.template_path(conn, :show, template))

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
      {:ok, template} ->
        conn
        |> put_flash(:info, "Template updated successfully.")
        |> redirect(to: Routes.template_path(conn, :show, template))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", template: template, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    template = TemplateManager.get_template!(id)
    {:ok, _template} = TemplateManager.delete_template(template)

    conn
    |> put_flash(:info, "Template deleted successfully.")
    |> redirect(to: Routes.template_path(conn, :index))
  end
end
