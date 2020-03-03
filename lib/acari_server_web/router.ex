defmodule AcariServerWeb.Router do
  use AcariServerWeb, :router
  import AcariServer.UserManager, only: [load_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NavigationHistory.Tracker, history_size: 11, excluded_paths: [~r(/login.*), ~r(/zabbix.*)]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Our pipeline implements "maybe" authenticated. We'll use the `:ensure_auth` below for when we need to make sure someone is logged in.
  pipeline :auth do
    plug AcariServer.UserManager.Pipeline
    plug :load_current_user
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", AcariServerWeb do
    pipe_through [:browser]

    get "/login", SessionController, :new
    post "/login", SessionController, :login
  end

  scope "/", AcariServerWeb do
    pipe_through [:browser, :auth]
    get "/noauth", PageController, :noauth
    get "/test", PageController, :test
  end

  # Definitely logged in scope
  scope "/", AcariServerWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    post "/logout", SessionController, :logout

    get "/", PageController, :index
    get "/zabbix", PageController, :zabbix
    get "/чеукь", PageController, :xterm
    post "/чеукь/upload", PageController, :upload
    get "/faq", PageController, :faq
    get "/help", PageController, :help

    get "/map", MapController, :index

    get "/tunnels", TunnelController, :index
    get "/tunnels/:id", TunnelController, :grp
    get "/tunnel/:name", TunnelController, :show

    get "/grpoper", GrpOperController, :index

    resources "/users", UserController
    get "/users/:id/rw", UserController, :show_rw
    resources "/groups", GroupController
    get "/groups/:id/oper", GroupController, :oper
    resources "/nodes", NodeController
    get "/nodes/:id/toggle_lock", NodeController, :toggle_lock
    delete "/nodes", NodeController, :exec_selected
    get "/nodes/grp/:id", NodeController, :client_grp
    resources "/newnodes", NewNodeController
    post "/newnodes/upload", NewNodeController, :upload
    get "/nodes/:id/unlock", NewNodeController, :unlock

    resources "/scripts", ScriptController
    resources "/templates", TemplateController
    get "/templates_diff/:id", TemplateController, :diff
    resources "/servers", ServerController
    resources "/notes", NoteController
    resources "/schedules", ScheduleController
    resources "/filters", FilterController

    get "/secret", PageController, :secret
  end

  scope "/api", AcariServerWeb.Api, as: :api do
    pipe_through(:api)
    post("/", AutoconfController, :index)
    get "/nodes_num", AuxController, :nodes_num
  end
end
