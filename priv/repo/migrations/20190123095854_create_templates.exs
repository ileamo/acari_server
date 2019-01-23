defmodule AcariServer.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add(:name, :string)
      add(:description, :string)
      add(:template, :text)
      add(:script_id, references(:scripts, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:templates, [:name]))
    create(index(:templates, [:script_id]))
  end
end
