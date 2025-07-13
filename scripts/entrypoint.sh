#!/bin/sh

# Checking for cert files
echo "=== Debug Information ==="
echo "Checking certificate files..."
ls -la /app/priv/certs/
echo ""

echo "Checking MQTT configuration..."
echo "MQTT_HOST: $MQTT_HOST"
echo "MQTT_PORT: $MQTT_PORT"
echo "MQTT_USE_TLS: $MQTT_USE_TLS"
echo "MQTT_CAFILE: $MQTT_CAFILE"
echo ""

# Wait until the database is ready
echo "Waiting for database..."
COUNT=0
MAX_TRIES=60

# Run db_ready function to check database availability
until /app/bin/telemetrix_umbrella eval "Telemetrix.Release.db_ready?()" 2>/dev/null || [ $COUNT -eq $MAX_TRIES ]; do
    sleep 1
    COUNT=$((COUNT+1))
    echo "Waiting for database... ($COUNT/$MAX_TRIES)"
done

if [ $COUNT -eq $MAX_TRIES ]; then
    echo "Database not reachable after $MAX_TRIES attempts."
    exit 1
fi

echo "Database is ready!"

# Migrate database when db is ready
echo "Running database migrations..."
/app/bin/telemetrix_umbrella eval "Telemetrix.Release.migrate()"
echo "Migrations completed."

# Start telemetrix
echo "Starting Telemetrix..."
exec /app/bin/telemetrix_umbrella start
