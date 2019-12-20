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
    field :test_client_name, :string
    belongs_to :script, AcariServer.ScriptManager.Script

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
      :executable,
      :validator,
      :rights,
      :test_client_name
    ])
    |> validate_required([:name, :description, :template])
    |> validate_change(:name, &validate_templ_name/2)
    |> foreign_key_constraint(:script_id)
    |> unique_constraint(:name)
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
end
