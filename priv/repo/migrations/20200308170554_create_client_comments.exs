defmodule AcariServer.Repo.Migrations.CreateClientComments do
  use Ecto.Migration

  def change do
    create table(:client_comments) do
      add :comment, :text
      add :user_id, references(:users, on_delete: :delete_all)
      add :node_id, references(:nodes, on_delete: :delete_all)

      timestamps()
    end

    create index(:client_comments, [:user_id])
    create index(:client_comments, [:node_id])
  end
end
