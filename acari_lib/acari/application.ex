defmodule Acari.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # AcariClient.Config,
      Acari.Sup,
      AcariServer.Sup,
      AcariClient.TunCreator
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Acari.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
