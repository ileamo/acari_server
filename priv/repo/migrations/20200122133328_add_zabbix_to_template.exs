defmodule AcariServer.Repo.Migrations.AddZabbixToTemplate do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add(:zabbix_send, :boolean, default: false, null: false)
      add(:zabbix_key, :string)
    end
  end
end
