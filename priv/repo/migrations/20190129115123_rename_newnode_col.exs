defmodule AcariServer.Repo.Migrations.RenameNewnodeCol do
  use Ecto.Migration

  def change do
    rename(table(:newnodes), :template, to: :source)
  end
end
