defmodule Telemetrix.Release do
  @moduledoc """
  Module for running migrations and other release-related tasks.
  """
  @app :telemetrix

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def db_ready? do
    load_app()

    try do
      # Try to connect to each repo
      for repo <- repos() do
        repo.query!("SELECT 1")
      end
      true
    rescue
      _ -> false
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
