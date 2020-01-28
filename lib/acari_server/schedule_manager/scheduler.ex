defmodule AcariServer.Scheduler do
  use Quantum.Scheduler,
    otp_app: :acari_server

  def init(config) do
    Task.start(__MODULE__, :init_task, [self()])

    config
  end

  def init_task(_master_pid) do
    Process.sleep(1_000)
    AcariServer.Scheduler.Api.update_script_jobs()
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
      # Group filter
      clients =
        case schedule.group do
          nil ->
            AcariServer.NodeManager.list_nodes()

          group ->
            group
            |> AcariServer.RepoRO.preload(:nodes)
            |> Map.get(:nodes)
        end

      # Class filter
      clients =
        case schedule.script_id do
          nil -> clients
          id -> clients |> Enum.filter(fn %{script_id: sid} -> sid == id end)
        end

      clients
      |> Enum.reduce(%{}, fn client, allow_map ->
        {allow_list, allow_map} =
          case allow_map[client.script_id] do
            nil ->
              allow_list = get_allowed_template(client.script_id)
              {allow_list, Map.put(allow_map, client.script_id, allow_list)}

            list ->
              {list, allow_map}
          end

        if Enum.member?(allow_list, schedule.template_id) do
          exec_script(schedule.template, client)
        end

        allow_map
      end)
    else
      _ -> Logger.error("Scheduler: No Schedule ##{shedule_id}")
    end
  end

  defp get_allowed_template(nil), do: []

  defp get_allowed_template(class_id) do
    case AcariServer.ScriptManager.get_script(class_id) do
      nil ->
        []

      class ->
        class
        |> AcariServer.RepoRO.preload(:templates)
        |> Map.get(:templates)
        |> Enum.map(fn %{id: id} -> id end)
    end
  end

  defp exec_script(template, client) do
    IO.inspect({template.name, client.name})
    AcariServer.Master.exec_script_on_peer(client.name, template.name)
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
