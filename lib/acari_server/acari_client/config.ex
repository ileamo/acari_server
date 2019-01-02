defmodule AcariClient.Config do
  use Agent

  def start_link(_) do
    Agent.start_link(&get_host_config/0, name: __MODULE__)
  end

  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  defp get_host_config() do
    %{
      env: get_host_env(),
      acari: get_acari_conf()
    }
  end

  @env_regex ~r/([^=\s]+)\s*=\s*([^=\s]+)\s/
  defp get_host_env() do
    env = read_all_file("priv/env")

    @env_regex
    |> Regex.scan(env <> "\n")
    |> Enum.map(fn [_, k, v] -> {k, v} end)
    |> Enum.into(%{})
  end

  defp get_acari_conf() do
    {:ok, conf} =
      read_all_file("priv/acari.json")
      |> Jason.decode()

    conf
  end

  defp read_all_file(file_name) do
    {:ok, file} = File.open(file_name, [:read])
    data = IO.read(file, :all)
    File.close(file)
    data
  end
end
