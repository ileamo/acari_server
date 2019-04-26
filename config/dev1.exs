use Mix.Config

config :acari_server, AcariServerWeb.Endpoint,
  http: [port: 4001],
  check_origin: false

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "$date $time [$level] $message\n", level: :info

# Configure your database
config :acari_server, AcariServer.Repo,
  username: "postgres",
  password: "postgres",
  database: "acari_server_dev",
  hostname: "localhost",
  pool_size: 10

config :acari_server, AcariServer.Listener,
  port: 51019,
  keyfile: "priv/cert/selfsigned_key.pem",
  certfile: "priv/cert/selfsigned.pem"

config :acari_server, :zabbix,
  zbx_listen_port: 51051,
  zbx_web_port: nil,
  # zbx_api_url: "http://10.0.10.155:4080",
  zbx_snd_host: "10.0.10.155",
  zbx_username: "Admin",
  zbx_password: "IMo19-0708"
