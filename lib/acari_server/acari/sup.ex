defmodule Acari.Sup do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {Registry, keys: :unique, name: Registry.TunMan},
      {Registry, keys: :unique, name: Registry.TunSup},
      Acari.TunsSup
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
