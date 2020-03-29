defmodule AcariServer.TemplateManager.Template do
  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :description, :string
    field :name, :string
    field :template, :string
    field :executable, :boolean, default: false
    field :validator, :string
    field :rights, :string, default: "rw"
    field :type, :string, default: "no"
    field :test_client_name, :string
    field :test_params, :string
    field :zabbix_send, :boolean, default: false
    field :zabbix_key, :string
    belongs_to :script, AcariServer.ScriptManager.Script
    has_many :schedules, AcariServer.ScheduleManager.Schedule


    # many_to_many :scripts, AcariServer.ScriptManager.Script,
    #  join_through: AcariServer.ScriptTemplateAssociation.ScriptTemplateNode

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :name,
      :description,
      :template,
      :script_id,
      :validator,
      :rights,
      :type,
      :test_client_name,
      :test_params,
      :zabbix_send,
      :zabbix_key
    ])
    |> validate_required([:name, :description, :template])
    |> foreign_key_constraint(:script_id)
    |> unique_constraint(:name)
    |> validate_change(:name, &validate_templ_name/2)
  end

  def update_changeset(template, attrs) do
    changeset(template, attrs)
    |> validate_change(:name, &validate_update_templ_name/2)
  end

  defp validate_templ_name(:name, "setup"), do: [name: "Имя шаблона не может быть 'setup'"]

  defp validate_templ_name(:name, name) do
    case String.match?(name, ~r|^[\w\d\._]+$|) do
      true ->
        []

      false ->
        [name: "Имя шаблона должно состоять из латинских букв, цифр и символов '_', '.'"]
    end
  end

  defp validate_update_templ_name(:name, _), do: [name: "Имя шаблона не может быть изменено"]

end
