import Config
# Logger configuration
config :logger, :console, format: "$date $time [$level] $message\n", level: :debug

# config :logger,
#   backends: [
#     {Loggix, :info_log},
#     {Loggix, :error_log}
#   ]
#
# config :logger, :info_log,
#   path: "/var/log/info.log",
#   format: "$date $time $metadata[$level] $message\n",
#   rotate: %{max_bytes: 2*1024*1024, keep: 5},
#   level: :info
#
# config :logger, :error_log,
#   path: "/var/log/error.log",
#   format: "$date $time $metadata[$level] $message\n",
#   rotate: %{max_bytes: 2*1024*1024, keep: 5},
#   level: :error

# Configure your database
config :acari_server, AcariServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.get_env("DB_HOST"),
  port: System.get_env("DB_PORT")

config :acari_server, AcariServer.RepoManager,
  rw: "10.0.10.10:55432,10.0.10.10:51432",
  ro: "10.0.10.10:51432,10.0.10.10:55432"

config :acari_server, AcariServer, allow_unconfigured: false

# config :acari_server, AcariServer.Listener,
#   port: 50019,
#   keyfile: "/etc/ssl/bogatka/ssl.key",
#   certfile: "/etc/ssl/bogatka/ssl.crt"

config :acari_server, :zabbix,
  zbx_ext_url: System.get_env("ZBX_EXT_URL"),
  zbx_web_port: System.get_env("ZBX_WEB_PORT"),
  zbx_api_url: System.get_env("ZBX_API_URL"),
  zbx_snd_host: System.get_env("ZBX_SND_HOST"),
  zbx_snd_port: System.get_env("ZBX_SND_PORT")

config :acari_server, :openstreetmap, provider_url: System.get_env("MAP_PROVIDER_URL")
