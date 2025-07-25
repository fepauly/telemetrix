import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
  if config_env() == :prod do
    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :telemetrix, Telemetrix.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # InfluxDB
  config :telemetrix, Telemetrix.Influx.InfluxConnection,
    auth: [method: :token, token: System.get_env("DOCKER_INFLUXDB_INIT_ADMIN_TOKEN")],
    bucket: System.get_env("DOCKER_INFLUXDB_INIT_BUCKET"),
    org: System.get_env("DOCKER_INFLUXDB_INIT_ORG"),
    host: "influxdb",
    port: 8086,
    version: :v2

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "dashboard.local"
  port = String.to_integer(System.get_env("PORT") || "4000")
  config :telemetrix_web, TelemetrixWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  # MQTT Configuration
  mqtt_host = System.get_env("MQTT_HOST") || "localhost"
  mqtt_port = String.to_integer(System.get_env("MQTT_PORT") || "8883")
  mqtt_username = System.get_env("MQTT_USERNAME")
  mqtt_password = System.get_env("MQTT_PASSWORD")
  mqtt_use_tls = System.get_env("MQTT_USE_TLS") == "true"
  mqtt_ca_certfile = System.get_env("MQTT_CAFILE") || "/app/priv/certs/mosquitto.crt"

  config :telemetrix, Telemetrix.MQTT,
    host: mqtt_host,
    port: mqtt_port,
    username: mqtt_username,
    password: mqtt_password,
    use_tls: mqtt_use_tls,
    ca_certfile: mqtt_ca_certfile,
    client_id: "telemetrix_server_#{:rand.uniform(999_999_999)}"

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :telemetrix_web, TelemetrixWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :telemetrix_web, TelemetrixWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :telemetrix_web, TelemetrixWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :telemetrix, Telemetrix.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney, Req and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :telemetrix, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
