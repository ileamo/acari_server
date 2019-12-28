defmodule AcariServer.Repo.Migrations.AddTestParamsToTempl do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:test_params, :text)
    end
  end
end
