defmodule AcariServerWeb.Api.AuxView do
  use AcariServerWeb, :view

  def render("result.json", _) do
     AcariServer.Mnesia.get_active_tun_chart()
  end

end
