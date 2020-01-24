defmodule AcariServer.Scheduler do
  use Quantum.Scheduler,
    otp_app: :acari_server

  def init(config) do
    IO.inspect(config, label: "Quantum")

    config
  end
end

defmodule AcariServer.Scheduler.Api do
  require Logger
  require AcariServer.Zabbix.ZbxConst, as: ZbxConst

  alias AcariServer.Scheduler

  def send_clients_number_to_zabbix() do
    {num, active} = AcariServer.Mnesia.get_clients_number()
    AcariServer.Zabbix.ZbxApi.zbx_send_master(ZbxConst.client_number_key(), to_string(num))
    AcariServer.Zabbix.ZbxApi.zbx_send_master(ZbxConst.client_active_key(), to_string(active))
  end

  def exec_script_on_schedule(shedule_id) do
    with %AcariServer.ScheduleManager.Schedule{} = schedule <-
           AcariServer.ScheduleManager.get_schedule(shedule_id) do
      IO.inspect(schedule)
    else
      _ -> Logger.error("Scheduler: No Schedule ##{shedule_id}")
    end
  end

  def add_job(schedule) do
    with {:ok, cron_expr} <- Crontab.CronExpression.Parser.parse(schedule.schedule) do
      Scheduler.add_job({cron_expr, {__MODULE__, :exec_script_on_schedule, [schedule.id]}})
    end
  end
end
