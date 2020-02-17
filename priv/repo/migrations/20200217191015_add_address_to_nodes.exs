defmodule AcariServer.Repo.Migrations.AddAddressToNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add(:address, :text)
    end

  end
end
