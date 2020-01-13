defmodule AcariServer.Repo.Migrations.CreateTemplateEvents do
  use Ecto.Migration

  def change do
    create table(:template_events) do
      add :template_name, :string
      add :username, :string
      add :template, :text
      add :description, :string

      timestamps()
    end

  end
end
