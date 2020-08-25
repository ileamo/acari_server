defmodule AcariServerWeb.Api.BogatkaView do
  use AcariServerWeb, :view

  def render("client.json", _) do
    %{
      result: "ok"
    }
  end

  def render("auth.json", %{username: username, jwt: jwt}) do
    %{
      username: username,
      jwt: jwt
    }
  end

  def render("api_error.json", reason) do
    %{
      error: reason
    }
  end

  def render("api_result.json", %{result: result}) do
    %{
      result: result
    }
  end
end
