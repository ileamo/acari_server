use Mix.Config

# Configure your database
config :acari_server, AcariServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "acari_server_prod",
  hostname: System.get_env("DB_HOST"),
  pool_size: 10

config :acari_server, AcariServer, allow_unconfigured: false

config :acari_server, AcariServer.Listener,
  port: 50019,
  keyfile: "priv/cert/selfsigned_key.pem",
  certfile: "priv/cert/selfsigned.pem"
