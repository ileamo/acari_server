defmodule AcariServer.Scheduler do
  use Quantum.Scheduler,
    otp_app: :acari_server
end
