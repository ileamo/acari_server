defmodule AcariServer.Zabbix.Sup do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      #AcariServer.Zabbix.Sender,
      AcariServer.Zabbix.LastDataAgent,
      AcariServer.Zabbix.SerSup,
      AcariServer.Zabbix.Listener
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
