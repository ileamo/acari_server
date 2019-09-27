defmodule AcariServer.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :subject, :string
      add :body, :text
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
  end
end
