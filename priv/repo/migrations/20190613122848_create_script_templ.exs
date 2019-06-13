defmodule AcariServer.Repo.Migrations.CreateScriptTempl do
  use Ecto.Migration

  def change do
    create table(:scripts_templates) do
      add(:script_id, references(:scripts, on_delete: :delete_all))
      add(:template_id, references(:templates, on_delete: :delete_all))
      timestamps()
    end

    create(
      unique_index(:scripts_templates, [:script_id, :template_id],
        name: :script_id_template_id_index
      )
    )
  end
end
