defmodule ColocatedDemoWeb.Router do
  use ColocatedDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ColocatedDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_csp
  end

  def put_csp(conn, _opts) do
    script_nonce = nonce()

    conn
    |> assign(:script_csp_nonce, script_nonce)
    |> put_session(:script_csp_nonce, script_nonce)
    |> put_resp_header(
      "content-security-policy",
      "default-src; script-src 'self' 'nonce-#{script_nonce}'; style-src-elem 'self' https://unpkg.com/@xterm/xterm@5.5.0/css/xterm.css 'unsafe-inline'; " <>
        "img-src data: 'self'; font-src data: ; connect-src 'self'; frame-src 'self' ; " <>
        "style-src 'self' 'unsafe-inline';"
    )
  end

  defp nonce do
    16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ColocatedDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/demo", Demo, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ColocatedDemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:colocated_demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: ColocatedDemoWeb.Telemetry,
        additional_pages: [
          terminal: ColocatedDemoWeb.LiveDashboard.TerminalPage
        ],
        on_mount: [
          ColocatedDemoWeb.LiveDashboard.Hooks
        ],
        csp_nonce_assign_key: %{
          script: :script_csp_nonce
        }

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
