defmodule AcariServerWeb.EndpointPub do
  use Phoenix.Endpoint, otp_app: :acari_server

  @session_options [
    store: :cookie,
    key: "_acari_server_key",
    signing_salt: "ZtutPWthp5Gq0Y6WFAFz9A5Sexd/Um9H"
  ]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Logger

  plug Plug.Parsers,
    body_reader: {CacheBodyReader, :read_body, []},
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 1_000_000_000

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug AcariServerWeb.RouterPub
end
