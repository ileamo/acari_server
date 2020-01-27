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
      IO.inspect({NaiveDateTime.utc_now(), schedule.id, schedule.description}, label: "JOB")
    else
      _ -> Logger.error("Scheduler: No Schedule ##{shedule_id}")
    end
  end

  def add_job(schedule) do
    with {:ok, cron_expr} <- Crontab.CronExpression.Parser.parse(schedule.schedule) do
      Scheduler.add_job({cron_expr, {__MODULE__, :exec_script_on_schedule, [schedule.id]}})
    end
  end

  def update_script_jobs() do
    job_list =
      Scheduler.jobs()
      |> Enum.filter(fn
        {_, %Quantum.Job{task: {AcariServer.Scheduler.Api, :exec_script_on_schedule, [_]}}} ->
          true

        _ ->
          false
      end)
      |> Enum.map(fn {ref, %{task: {_, _, [n]}}} -> {ref, n} end)

    job_id_list = job_list |> Enum.map(fn {_, n} -> n end)

    schedule_list = AcariServer.ScheduleManager.list_schedules()
    schedule_id_list = schedule_list |> Enum.map(fn %{id: n} -> n end)


    # Del Jobs
    job_list
    |> Enum.reject(fn {_, id} -> Enum.member?(schedule_id_list, id) end)
    |> Enum.each(fn {ref, _} -> Scheduler.delete_job(ref) end)

    # Add Job
    schedule_list
    |> Enum.reject(fn %{id: id} -> Enum.member?(job_id_list, id) end)
    |> Enum.each(fn sched -> add_job(sched) end)
  end
end
