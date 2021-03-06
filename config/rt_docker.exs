import Config
# Logger configuration
config :logger,
  backends: [
    {Loggix, :info_log},
    {Loggix, :error_log}
  ]

config :logger, :info_log,
  path: "/var/log/info.log",
  format: "$date $time $metadata[$level] $message\n",
  rotate: %{max_bytes: 2 * 1024 * 1024, keep: 5},
  level: :info

config :logger, :error_log,
  path: "/var/log/error.log",
  format: "$date $time $metadata[$level] $message\n",
  rotate: %{max_bytes: 2 * 1024 * 1024, keep: 5},
  level: :error

# Configure your database
config :acari_server, AcariServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.get_env("DB_HOST"),
  port: System.get_env("DB_PORT")

config :acari_server, AcariServer.RepoManager,
  rw: System.get_env("DB_HOSTS_RW"),
  ro: System.get_env("DB_HOSTS_RO")

config :acari_server, AcariServer, allow_unconfigured: false

config :acari_server, AcariServer.Listener,
  port: 50019,
  keyfile: "/etc/ssl/bogatka/ssl.key",
  certfile: "/etc/ssl/bogatka/ssl.crt"

config :acari_server, :zabbix,
  zbx_ext_url: System.get_env("ZBX_EXT_URL"),
  zbx_web_port: System.get_env("ZBX_WEB_PORT"),
  zbx_api_url: System.get_env("ZBX_API_URL"),
  zbx_snd_host: System.get_env("ZBX_SND_HOST"),
  zbx_snd_port: AcariServer.system_get_integer_env("ZBX_SND_PORT"),
  zbx_api_url_2: System.get_env("ZBX_API_URL_2"),
  zbx_snd_host_2: System.get_env("ZBX_SND_HOST_2"),
  zbx_snd_port_2: AcariServer.system_get_integer_env("ZBX_SND_PORT_2")

config :acari_server, :openstreetmap, provider_url: System.get_env("MAP_PROVIDER_URL")

config :acari_server, AcariServerWeb.Endpoint,
  secret_key_base: AcariServer.Application.random_string(64),
  live_view: [signing_salt: AcariServer.Application.random_string(32)]
