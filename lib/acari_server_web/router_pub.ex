defmodule AcariServerWeb.RouterPub do
  use AcariServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AcariServerWeb.Api, as: :api do
    pipe_through(:api)
    post("/", AutoconfController, :index)
  end
end
