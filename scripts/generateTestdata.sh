#!/bin/bash

# Script to run test publish to mqtt broker
HOST="localhost"  # running from localhost
PORT=8883         
USER="esp32home"
PASS=${MQTT_PASSWORD}
CAFILE=${MQTT_CAFILE}
TOPIC="esp32/force"
COUNT=5

echo "Send $COUNT test message to $HOST:$PORT"
echo "Topic: $TOPIC"
echo "------------------------------------"

for ((i=1; i<=COUNT; i++))
do
  VALUE=$(awk -v min=20 -v max=30 'BEGIN{srand(); printf "%.2f", min+rand()*(max-min)}')
  TS=$(date +%s)
  PAYLOAD="{\"value\": $VALUE, \"timestamp\": $TS}"
  
  echo "[$i/$COUNT] Send: $PAYLOAD"
  
  mosquitto_pub -h "$HOST" -p "$PORT" --cafile "$CAFILE" -u "$USER" -P "$PASS" -t "$TOPIC" -m "$PAYLOAD" -d 
  
  if [ $i -lt $COUNT ]; then
    sleep 1
  fi
done

