defmodule AcariServerWeb.Api.AuxView do
  use AcariServerWeb, :view

  def render("result.json", _) do
    AcariServer.NodeNumbersAgent.get()
  end

end
