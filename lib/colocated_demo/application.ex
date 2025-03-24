defmodule ColocatedDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ColocatedDemoWeb.Telemetry,
      ColocatedDemo.Repo,
      {DNSCluster, query: Application.get_env(:colocated_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ColocatedDemo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ColocatedDemo.Finch},
      # Start a worker by calling: ColocatedDemo.Worker.start_link(arg)
      # {ColocatedDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      ColocatedDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ColocatedDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ColocatedDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
