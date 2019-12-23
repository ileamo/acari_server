defmodule AcariServer.Repo.Migrations.AddTestClientNameToClass do
  use Ecto.Migration

  def change do
    alter table(:scripts) do
      add(:test_client_name, :string)
    end
  end
end
