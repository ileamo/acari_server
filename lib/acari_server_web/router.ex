defmodule AcariServerWeb.Router do
  require Logger
  use AcariServerWeb, :router
  import AcariServer.UserManager, only: [load_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug NavigationHistory.Tracker,
      history_size: 11,
      excluded_paths: [~r(/login.*), ~r(/zabbix.*)]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Our pipeline implements "maybe" authenticated. We'll use the `:ensure_auth` below for when we need to make sure someone is logged in.
  pipeline :auth do
    plug AcariServer.UserManager.Pipeline
    plug :load_current_user
    plug :put_root_layout, {AcariServerWeb.LayoutView, :root}
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  import AcariServer.UserManager, only: [is_admin: 2]

  pipeline :ensure_admin do
    plug :is_admin
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
    get "/chat", PageController, :chat

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
    post "/client_comment/new", NodeController, :client_comment_new
    get "/client_comment/del/:id", NodeController, :client_comment_del

    resources "/newnodes", NewNodeController
    post "/newnodes/upload", NewNodeController, :upload
    get "/nodes/:id/unlock", NewNodeController, :unlock

    resources "/scripts", ScriptController
    resources "/templates", TemplateController
    post "/templates/import", TemplateController, :import
    get "/templates_export", TemplateController, :export
    get "/templates_diff/:id", TemplateController, :diff

    resources "/servers", ServerController
    resources "/notes", NoteController
    resources "/schedules", ScheduleController
    resources "/filters", FilterController
    resources "/audit_logs", AuditController, only: [:index, :show]

    get "/secret", PageController, :secret

    live "/live", PageLive
  end

  scope "/api", AcariServerWeb.Api, as: :api do
    pipe_through(:api)
    post("/", AutoconfController, :index)
    get "/nodes_num", AuxController, :nodes_num
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through [:browser, :auth, :ensure_auth, :ensure_admin]
    live_dashboard "/system_dashboard", metrics: AcariServerWeb.Telemetry
  end

  scope "/" do
    forward "/zbx", ReverseProxyPlug,
      upstream: &AcariServer.Zabbix.ZbxApi.zbx_get_api_url/0,
      error_callback: &__MODULE__.log_reverse_proxy_error/1

    forward "/zbx2", ReverseProxyPlug2,
      upstream: &AcariServer.Zabbix.ZbxApi.zbx_get_api_url2/0,
      error_callback: &__MODULE__.log_reverse_proxy_error/1

    def log_reverse_proxy_error(error) do
      Logger.warn("ReverseProxyPlug network error: #{inspect(error)}")
    end
  end
end
