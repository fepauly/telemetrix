FROM hexpm/elixir:1.18.4-erlang-28.0.1-alpine-3.21.3 AS build

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    npm

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files for dependency installation
COPY mix.exs mix.lock ./
COPY config config
COPY apps apps

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Install packages
COPY apps/telemetrix_web/assets/package*.json ./apps/telemetrix_web/assets/
RUN cd apps/telemetrix_web/assets && npm install

# Copy assets
COPY apps/telemetrix_web/assets ./apps/telemetrix_web/assets
COPY apps/telemetrix_web/priv ./apps/telemetrix_web/priv

# Compile assets
RUN cd apps/telemetrix_web && \
    mix assets.setup && \
    mix assets.deploy

# Compile the application
RUN mix compile

# Build the release
RUN mix release

# App image
FROM hexpm/elixir:1.18.4-erlang-28.0.1-alpine-3.21.3 AS app

# Install runtime dependencies
RUN apk add --no-cache libstdc++ ncurses-libs openssl

ENV LANG=C.UTF-8

WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/telemetrix_umbrella ./

# Create directory for certificates
RUN mkdir -p /app/priv/certs

# Copy certificates for MQTT TLS (HTTPS is done by nginx)
COPY ./mosquitto/rootCA.pem /app/priv/certs/mosquitto.crt


# Copy entrypoint script
COPY scripts/entrypoint.sh /app/

# Set command to start the server
CMD ["/app/entrypoint.sh"]
