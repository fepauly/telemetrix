import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :telemetrix, Telemetrix.Repo,
  database: Path.expand("../telemetrix_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :telemetrix_web, TelemetrixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gSyEqmlKnZWMewndrdSgm08IoVn7pAC2pJPEt2c2bDAzVylFhiIsPX8lEaXkx6c2",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :telemetrix, Telemetrix.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
