defmodule AcariServer.Repo.Migrations.AddTemplateValidator do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:validator, :string)
    end

  end
end
