#!/bin/bash

echo "Preparing for deployment..."

# Create directories if they don't exist
mkdir -p certs
mkdir -p mosquitto

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "Error: mkcert is not installed!"
    echo "Please install mkcert:"
    echo "  - Linux: apt install mkcert or equivalent for your distribution"
    exit 1
fi

# Generate SSL certificates
echo "Generating SSL certificates for the web app and MQTT..."
./generate-certs.sh

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp .env.example .env
    
    # Generate Phoenix secret key
    if command -v mix &> /dev/null; then
        echo "Generating SECRET_KEY_BASE..."
        SECRET_KEY=$(mix phx.gen.secret)
        # Replace placeholder in .env file
        sed -i "s/SECRET_KEY_BASE=changeme_generate_with_mix_phx_gen_secret/SECRET_KEY_BASE=$SECRET_KEY/" .env
        echo "SECRET_KEY_BASE has been generated and added to .env"
    else
        echo "Warning: mix is not available. Please generate SECRET_KEY_BASE manually and add it to .env"
    fi
else
    echo ".env file already exists."
fi

echo "Update remaining secrets in .env!"
echo "Then run 'docker-compose up -d' to start the containers."
