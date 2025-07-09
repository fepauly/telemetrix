defmodule Telemetrix.Repo do
  use Ecto.Repo,
    otp_app: :telemetrix,
    adapter: Ecto.Adapters.Postgres
end
