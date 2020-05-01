defmodule AcariServer.Presence do
  use Phoenix.Presence, otp_app: :acari_server,    pubsub_server: AcariServer.PubSub
end
