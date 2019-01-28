defmodule Acari.TunSup do
  use Supervisor

  def start_link(params) do
    tun_name = Map.fetch!(params, :tun_name)
    Supervisor.start_link(__MODULE__, params, name: {:via, Registry, {Registry.TunSup, tun_name}})
  end

  @impl true
  def init(params) do
    # List all child processes to be supervised
    children = [
      {Acari.TunMan, params |> Map.put(:tun_sup_pid, self())}
    ]

    opts = [strategy: :one_for_all, name: Acari.Supervisor]
    Supervisor.init(children, opts)
  end
end
