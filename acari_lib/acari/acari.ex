defmodule Acari do
  require Logger

  defdelegate start_tun(name, pid \\ nil, request \\ %{}), to: Acari.TunsSup
  defdelegate stop_tun(name), to: Acari.TunsSup
  defdelegate tun_exist?(name), to: Acari.TunsSup
  defdelegate add_link(tun_name, link_name, connector), to: Acari.TunMan
  defdelegate del_link(tun_name, link_name), to: Acari.TunMan
  defdelegate get_all_links(tun_name), to: Acari.TunMan
  defdelegate send_json_request(tun_name, payload), to: Acari.TunMan
  defdelegate send_master_mes(tun_name, payload), to: Acari.TunMan

  def exec_sh(script, env \\ []) do
    Task.start(fn ->
      case System.cmd("sh", ["-c", script |> String.replace("\r\n", "\n")],
             stderr_to_stdout: true,
             env: env
           ) do
        {data, 0} -> data
        {err, code} -> Logger.warn("Script `#{script}` exits with code #{code}, output: #{err}")
      end
    end)
  end
end
