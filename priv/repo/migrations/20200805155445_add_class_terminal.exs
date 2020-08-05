defmodule AcariServer.Repo.Migrations.AddClassTerminal do
  use Ecto.Migration

  def change do
    create table(:classes_terminals) do
      add(:script_id, references(:scripts, on_delete: :delete_all))
      add(:template_id, references(:templates, on_delete: :delete_all))
      timestamps()
    end

    create(
      unique_index(:classes_terminals, [:script_id, :template_id],
        name: :class_id_terminal_id_index
      )
    )

  end
end
