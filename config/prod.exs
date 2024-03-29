import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.

config :acari_server, AcariServerWeb.Endpoint,
  http: [port: 50080],
  https: [
    port: 50443,
    keyfile: "/etc/ssl/bogatka/ssl.key",
    # cacertfile: "/etc/ssl/acari/chain.pem",
    certfile: "/etc/ssl/bogatka/ssl.crt",
    cipher_suite: :strong
    # versions: [:"tlsv1.2", :"tlsv1.1", :tlsv1, :sslv3]
  ],

  # This is critical for ensuring web-sockets properly authorize.
  url: [host: "localhost", port: 50443],
  check_origin: false,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  # debug_errors: true,
  version: Application.spec(:acari_server, :vsn)

config :acari_server, AcariServerWeb.EndpointPub,
  https: [
    port: 50444,
    keyfile: "/etc/ssl/bogatka/ssl.key",
    # cacertfile: "/etc/ssl/acari/chain.pem",
    certfile: "/etc/ssl/bogatka/ssl.crt",
    cipher_suite: :strong
    # versions: [:"tlsv1.2", :"tlsv1.1", :tlsv1, :sslv3]
  ],
  server: true

# Do not print debug messages in production
config :logger, level: :info

config :acari_server, AcariServer.Listener,
  port: 50019,
  keyfile: "priv/cert/selfsigned_key.pem",
  certfile: "priv/cert/selfsigned.pem"

# import_config "docker.secret.exs"
