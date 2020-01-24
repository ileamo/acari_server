defmodule AcariServer.Scheduler do
  use Quantum.Scheduler,
    otp_app: :acari_server

  require AcariServer.Zabbix.ZbxConst, as: ZbxConst

  def init(config) do
    IO.inspect(config, label: "Quantum")
    config
  end

  def send_clients_number_to_zabbix() do
    {num, active} = AcariServer.Mnesia.get_clients_number()
    AcariServer.Zabbix.ZbxApi.zbx_send_master(ZbxConst.client_number_key(), to_string(num))
    AcariServer.Zabbix.ZbxApi.zbx_send_master(ZbxConst.client_active_key(), to_string(active))
  end
end
