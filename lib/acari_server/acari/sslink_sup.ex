defmodule Acari.SSLinkSup do
  use DynamicSupervisor, restart: :temporary

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg)
  end

  defdelegate start_sslink(sup, spec), to: DynamicSupervisor, as: :start_child

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
