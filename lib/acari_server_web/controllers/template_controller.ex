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

  defp slice(str) do
    if String.length(str) > 80 do
      String.slice(str, 0, 80) <> "..."
    else
      str
    end
  end

  def export(conn, %{"list" => list}) do
    json =
      list
      |> String.split(",")
      |> Enum.map(fn id -> AcariServer.TemplateManager.get_template(id) end)
      |> Enum.filter(& &1)
      |> Enum.map(fn t ->
        %{
          description: t.description,
          executable: t.executable,
          name: t.name,
          rights: t.rights,
          template: t.template,
          test_params: t.test_params,
          type: t.type,
          validator: t.validator,
          zabbix_key: t.zabbix_key,
          export: t.export
        }
      end)
      |> Jason.encode()

    case json do
      {:ok, content} ->
        conn
        |> put_flash(:info, "Шаблоны экспортированы")
        |> send_download({:binary, content},
          filename:
            "bogatka_templates_" <>
              (NaiveDateTime.utc_now() |> to_string() |> String.replace(" ", "_")) <> ".json"
        )

      _ ->
        conn
        |> redirect(to: Routes.template_path(conn, :index))
    end
  end

  def import(conn, params) do
    {type, mes} =
      with %{path: path} <- params["upload"],
           {:ok, json} <- File.read(path),
           {:ok, templates} <- Jason.decode(json),
           :ok <- if(is_list(templates), do: :ok, else: {:error, "Должен быть список шаблонов"}) do
        res =
          templates
          |> Enum.map(fn
            %{} = params ->
              case TemplateManager.create_template(params) do
                {:ok, _} ->
                  nil

                {:error, %{changes: %{name: name}, errors: [name: {"has already been taken", _}]}} ->
                  "#{name}: Уже существует"

                {:error, %{changes: %{name: name}, errors: err}} ->
                  "#{name}: #{inspect(err) |> slice()}"

                res ->
                  inspect(res)
              end

            _ ->
              nil
          end)
          |> Enum.filter(& &1)

        {:info,
         case res do
           [] ->
             "Шаблоны успешно импортированы"

           list ->
             "Шаблоны импортированы кроме:<br>#{Enum.join(list, "<br>")}"
             |> Phoenix.HTML.raw()
         end}
      else
        nil -> {:error, "Ошибка импорта: файл не выбран"}
        {:error, res} -> {:error, "Ошибка импорта: #{inspect(res)}"}
        res -> {:error, "Ошибка импорта: #{inspect(res)}"}
      end

    conn
    |> put_flash(type, mes)
    |> redirect(to: Routes.template_path(conn, :index))
  end
end
