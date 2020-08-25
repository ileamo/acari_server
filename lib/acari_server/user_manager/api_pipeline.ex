defmodule AcariServer.UserManager.APIPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :acari_server,
    error_handler: AcariServer.UserManager.APIErrorHandler,
    module: AcariServer.UserManager.Guardian

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
