# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :acari_server,
  ecto_repos: [AcariServer.Repo]

# Configures the endpoint
config :acari_server, AcariServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "m/N7ZJoj+UaMtvJvhdxYi8NJTR5s8FTfvrF6QjhiO89uGtxopT6YS8fCXc44rjYg",
  render_errors: [view: AcariServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AcariServer.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
