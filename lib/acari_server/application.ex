defmodule AcariServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    set_secret_key()
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      AcariServer.RepoManager,
      AcariServer.Repo,
      AcariServer.RepoRO,

      AcariServerWeb.Telemetry,

      # Start the endpoint when the application starts
      AcariServerWeb.Endpoint,
      {Phoenix.PubSub, [name: AcariServer.PubSub, adapter: Phoenix.PubSub.PG2]},
      AcariServer.Presence,
      # Starts a worker by calling: AcariServer.Worker.start_link(arg)
      # {AcariServer.Worker, arg},
      AcariServer.TermSup,
      Acari.Sup,
      AcariServer.TemplateAgent,
      AcariServer.NodeMonitorAgent,
      AcariServer.ServerMonitor,
      AcariServer.Zabbix.ZbxApi,
      AcariServer.Zabbix.Sup,
      AcariServer.Sup,
      {Task.Supervisor, name: AcariServer.TaskSup},

      AcariServer.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AcariServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_state) do
    IO.puts("Application exited")
    :init.stop()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AcariServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def set_secret_key() do
    :ets.new(:secret, [:set, :protected, :named_table])

    secret_key =
      JOSE.JWS.generate_key(%{"alg" => "HS512"})
      |> JOSE.JWK.to_map()
      |> elem(1)
      |> Map.take(["k", "kty"])

    :ets.insert(:secret, {:guardian_secret_key, secret_key})
  end

  def get_secret_key() do
    :ets.lookup_element(:secret, :guardian_secret_key, 2)
  end
end
