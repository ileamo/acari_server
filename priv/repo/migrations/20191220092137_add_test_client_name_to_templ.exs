defmodule AcariServer.Repo.Migrations.AddTestClientNameToTempl do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:test_client_name, :string)
    end
  end
end
