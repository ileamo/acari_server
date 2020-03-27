defmodule AcariServer.TemplateManager do
  @moduledoc """
  The TemplateManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.TemplateManager.Template

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates do
    RepoRO.all(Template)
  end

  def templ_name_list(no_templ \\ "<NO_TEMPL>") do
    list_templates()
    |> Enum.filter(fn %{executable: ex} -> ex end)
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.sort()
    |> List.insert_at(0, {no_templ, nil})
  end

  def templ_name_id_pairs_list() do
    list_templates()
    |> Enum.filter(fn %{executable: ex} -> ex end)
    |> Enum.map(fn %{id: id, name: name, description: descr} -> {"#{descr} (#{name})", id} end)
    |> Enum.sort()
  end

  @type_id_list [
    {"Клиент", "client"},
    {"Сервер", "server"},
    {"Zabbix", "zabbix"},
    {"Текст", "text"},
    {"Вставка", "include"},
    {"Нет", "no"}
  ]

  def templ_type_id_list() do
    @type_id_list
  end

  def get_name_by_type() do
    @type_id_list
    |> Enum.map(fn {name, type} -> {type, name} end)
    |> Enum.into(%{})
  end

  def script_list(tun_name) do
    with node <- AcariServer.NodeManager.get_node_with_class(tun_name, :templates),
         script when is_map(script) <- node |> Map.get(:script),
         templ when is_list(templ) <- script |> Map.get(:templates) do
      templ
      |> Enum.map(fn %{name: name, description: descr} -> {descr, name} end)
      |> Enum.sort()
    else
      _ -> []
    end
  end

  def srv_script_list(tun_name) do
    with node <- AcariServer.NodeManager.get_node_with_class(tun_name, :local),
         class when is_map(class) <- node |> Map.get(:script),
         templ = %Template{} <- class |> Map.get(:local) do
      [{templ.description, templ.name}]
    else
      _ -> []
    end
  end

  def get_templ_names_ex_noex() do
    list_templates()
    |> Enum.reduce([[], []], fn %{name: name, executable: ex}, [ex_list, list] ->
      case ex do
        true -> [[name | ex_list], list]
        _ -> [ex_list, [name | list]]
      end
    end)
    |> Enum.map(fn list -> Enum.sort(list) end)
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id) do
    RepoRO.get_wait(Template, id)
    |> RepoRO.preload(:script)
  end

  def get_template_by_name(name) do
    Template
    |> RepoRO.get_by(name: name)
  end

  @doc """
  Creates a template.

  ## Examples

      iex> create_template(%{field: value})
      {:ok, %Template{}}

      iex> create_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update_template(template, %{field: new_value})
      {:ok, %Template{}}

      iex> update_template(template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Template.

  ## Examples

      iex> delete_template(template)
      {:ok, %Template{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template(%Template{} = template) do
    res = Repo.delete_wait(template)
    AcariServer.Scheduler.Api.update_script_jobs()
    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change_template(template)
      %Ecto.Changeset{source: %Template{}}

  """
  def change_template(%Template{} = template) do
    Template.changeset(template, %{})
  end
end
