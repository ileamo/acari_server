defmodule AcariServerWeb.Router do
  use AcariServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Our pipeline implements "maybe" authenticated. We'll use the `:ensure_auth` below for when we need to make sure someone is logged in.
  pipeline :auth do
    plug AcariServer.UserManager.Pipeline
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", AcariServerWeb do
    pipe_through [:browser, :auth]

    get "/login", SessionController, :new
    post "/login", SessionController, :login
    post "/logout", SessionController, :logout

    get "/", PageController, :index
    resources "/users", UserController
  end

  # Definitely logged in scope
  scope "/", AcariServerWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    get "/secret", PageController, :secret
  end

  # Other scopes may use custom stacks.
  # scope "/api", AcariServerWeb do
  #   pipe_through :api
  # end
end
