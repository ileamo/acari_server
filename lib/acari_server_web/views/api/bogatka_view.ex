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

  def render("api_error.json", %{payload: payload}) do
    %{
      error: payload
    }
  end

  def render("api_result.json", %{payload: payload}) do
    %{
      result: payload
    }
  end

end
