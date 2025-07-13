#!/bin/bash

echo "Generating SSL certificates for the Telemetrix web app..."

# Create directories for SSL certificates
mkdir -p certs
mkdir -p mosquitto

# Install Root CA if needed
echo "Installing Root CA..."
mkcert -install

# Copy mkcert Root CA
echo "Copying Root CA to the mosquitto directory..."
cp "$(mkcert -CAROOT)/rootCA.pem" mosquitto/rootCA.pem

# Generate certificates for the telemetrix web app
echo "Generating certificates for the web app (url dashboard.local)..."
mkcert -cert-file certs/dashboard.local.pem -key-file certs/dashboard.local-key.pem dashboard.local

# Generate certificates for MQTT
echo "Generating certificates for MQTT..."
mkcert -cert-file mosquitto/mosquitto.pem -key-file mosquitto/mosquitto-key.pem mosquitto localhost dashboard.local 127.0.0.1 192.168.2.55

echo "SSL certificates have been successfully generated:"
echo "Web application:"
echo "  certs/dashboard.local.pem - Certificate"
echo "  certs/dashboard.local-key.pem - Private key"
echo "MQTT:"
echo "  mosquitto/mosquitto.pem - Certificate"
echo "  mosquitto/mosquitto-key.pem - Private key"
echo "  mosquitto/rootCA.pem - Root CA certificate"

# Set permissions to avoid mosquitto warnings
chmod 644 certs/* mosquitto/*.pem

echo "Certificate generation completed!"
