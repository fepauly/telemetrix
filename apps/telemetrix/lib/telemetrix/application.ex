defmodule Telemetrix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Telemetrix.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:telemetrix, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:telemetrix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Telemetrix.PubSub}
      # Start a worker by calling: Telemetrix.Worker.start_link(arg)
      # {Telemetrix.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Telemetrix.Supervisor)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
