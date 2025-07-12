#!/bin/bash

echo "Tests connection to database..."
echo "----------------------------------------"

# Request data from the database
docker exec -it telemetrix-postgres-1 psql -U postgres -d telemetrix -c "SELECT * FROM sensor_readings ORDER BY timestamp DESC LIMIT 10;"

echo "Test subscriptions:"
docker exec -it telemetrix-postgres-1 psql -U postgres -d telemetrix -c "SELECT * FROM subscriptions;"
