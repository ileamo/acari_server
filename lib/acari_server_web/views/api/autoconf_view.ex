defmodule AcariServerWeb.Api.AutoconfView do
  use AcariServerWeb, :view
  alias AcariServerWeb.Api.AutoconfView

  def render("result.json", %{id: id, result: result}) do
    %{"id" => id, "result" => result}
  end

  def render("error.json", %{id: id, error: err}) do
    %{"id" => id, "error" => err}
  end
end
