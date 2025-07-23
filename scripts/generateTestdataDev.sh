#!/bin/bash

# Script to run test publish to mqtt broker
HOST=${MQTT_HOST:-"localhost"}  # Default to dashboard.local if not set
PORT=${MQTT_PORT:-"8883"}             # Default to 8883 if not set
USER=${MQTT_USERNAME:-"esp32home"}    # Default to esp32home if not set (my local setup)
PASS=${MQTT_PASSWORD:-"#esp32home"}
TOPIC=${MQTT_TOPIC:-"esp32/temp"}
COUNT=${MQTT_COUNT:-60}     

echo "Send $COUNT test message to $HOST:$PORT"
echo "Topic: $TOPIC"
echo "------------------------------------"

for ((i=1; i<=COUNT; i++))
do
  VALUE=$(awk -v min=20 -v max=30 'BEGIN{srand(); printf "%.2f", min+rand()*(max-min)}')
  PAYLOAD="{\"value\": $VALUE}"
  
  echo "[$i/$COUNT] Send: $PAYLOAD"
  
  mosquitto_pub -h "$HOST" -p "$PORT"  -u "$USER" -P "$PASS" -t "$TOPIC" -m "$PAYLOAD" -d 
  
  if [ $i -lt $COUNT ]; then
    sleep 1
  fi
done

