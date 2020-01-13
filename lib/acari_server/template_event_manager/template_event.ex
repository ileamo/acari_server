defmodule AcariServer.TemplateEventManager.TemplateEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "template_events" do
    field :description, :string
    field :template, :string
    field :template_name, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(template_event, attrs) do
    template_event
    |> cast(attrs, [:template_name, :username, :template, :description])
    |> validate_required([:template_name, :username, :template, :description])
  end
end
