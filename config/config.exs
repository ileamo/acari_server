# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :acari_server,
  ecto_repos: [AcariServer.Repo],
  release_date: NaiveDateTime.utc_now() |> to_string()

# Configures the endpoint
config :acari_server, AcariServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "m/N7ZJoj+UaMtvJvhdxYi8NJTR5s8FTfvrF6QjhiO89uGtxopT6YS8fCXc44rjYg",
  render_errors: [view: AcariServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: AcariServer.PubSub,
  live_view: [signing_salt: "bTQVwA3DJ5SYp3uFZhI+j99TSsTwOeMf"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :acari_server, AcariServer.UserManager.Guardian,
  issuer: "acari_server",
  ttl: {18 * 60, :minute},
  # secret_key: "QnnO7bOCfdYvMULODFxFzDJ+75h5Y7t/CV8d36zYSUncM/0oQtib3DejlUgSONb7"
  secret_key: {AcariServer.Application, :get_secret_key, []}

config :acari_server, AcariServerWeb.Gettext, default_locale: "ru"

config :acari,
  server: true

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :acari_server, AcariServer.Scheduler,
  debug_logging: false,
  run_strategy: Quantum.RunStrategy.Local,
  timezone: "Europe/Moscow",
  jobs: [
    # Every minute
    {"* * * * *", {AcariServer.Scheduler.Api, :send_clients_number_to_zabbix, []}},
    {"17 * * * *", {AcariServer.Scheduler.Api, :purge_status_messages, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
