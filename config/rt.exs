import Config
# Logger configuration
config :logger, :console, format: "$date $time [$level] $message\n", level: :debug
# Configure your database

config :acari_server, AcariServer.Repo,
  hostname: "localhost",
  port: 5432

config :acari_server, AcariServer.RepoManager,
  rw: "localhost:5432",
  ro: "localhost:5432"

config :acari_server, AcariServer, allow_unconfigured: false

config :acari_server, AcariServer.Listener,
  port: 50019,
  keyfile: "priv/cert/selfsigned_key.pem",
  certfile: "priv/cert/selfsigned.pem"
