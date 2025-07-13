# Deployment Guide for Telemetrix

This guide explains how to deploy Telemetrix to a Raspberry Pi on your local network.

## Prerequisites

- A Raspberry Pi with SSH access - I'm using a Raspberry Pi 4 Model B
- Docker and Docker Compose installed on your development machine
- Ansible installed on your development machine
- Basic knowledge of networking and Linux

## Deployment Methods

Telemetrix can be deployed in two ways:
1. Manual Docker deployment
2. Automated Ansible deployment

## Docker Deployment

### 1. Generate Certificates

SSL certificates are required for secure MQTT and web communication:

```bash
./scripts/generate-certs.sh
```

This script creates:
- Web certificates in `/certs/`
- MQTT certificates in `/mosquitto/`

### 2. Configure Environment Variables

Create a `.env` file in the project root:

```bash
# PostgreSQL
POSTGRES_USER=telemetrix
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=telemetrix

# Phoenix
SECRET_KEY_BASE=your_secret_key_base

# MQTT
MQTT_USERNAME=telemetrix
MQTT_PASSWORD=your_mqtt_password
MQTT_HOST=mosquitto
MQTT_PORT=8883
MQTT_USE_TLS=true

# Deployment
PHX_HOST=dashboard.local
PORT=4000
```

For `SECRET_KEY_BASE`, generate a secure value with:
```bash
mix phx.gen.secret
```

### 3. Setup MQTT Authentication

Create a password file for Mosquitto:
```bash
mosquitto_passwd -c /mosquitto/mosquitto_passwd telemetrix your_mqtt_password
```

> Make sure to add authentification for your IoT devices as well!

### 4. Build and Start Docker Containers

```bash
docker-compose up -d
```

## Ansible Deployment

Ansible automates the deployment process to your Raspberry Pi. Make sure to set a static IP adress for your Rapsberry Pi.

### 1. Generate Certificates

As described for local deployment.

### 2. Configure Ansible Inventory

Edit `ansible/inventory.yml` to match your Raspberry Pi's IP address and SSH settings:

```yaml
all:
  hosts:
    raspberrypi:
      ansible_host: 192.168.x.x
      ansible_user: your_username
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

### 3. Configure Secrets

Create a secrets file using ansible-vault:

```bash
ansible-vault create ansible/secrets.yml
```

Edit `ansible/secrets.yml` using `ansible-vault edit ansible/secrets.yml`:

```yaml
secret_key_base: your_generated_secret_key
postgres_password: your_secure_postgres_password
mqtt_password: your_secure_mqtt_password
```

### 4. Run the Ansible Playbook

From the project root directory:

```bash
cd ansible
ansible-playbook -i inventory.yml deploy.yml --ask-vault-pass
```

## Connecting External Devices to MQTT

### Connecting from ESP32 or Other IoT Devices

To connect your ESP32 or other IoT devices to the MQTT broker running on your Raspberry Pi:

1. **Use the correct hostname**: Use the Raspberry Pi's IP address or hostname (e.g., `dashboard.local`) when connecting.

2. **Install the Root CA certificate**: Your IoT device will need the Root CA certificate to establish a secure connection:

3. **Configure port and credentials**: Use port 8883 (TLS) and the credentials you configured in the Mosquitto password file.

### Testing MQTT Connectivity

Use the provided test script to verify connectivity from your development machine:

```bash
# Install mosquitto clients if needed
sudo apt install mosquitto-clients

# Set required environment variables
export MQTT_PASSWORD=your_mqtt_password
export MQTT_HOST=dashboard.local

# Run the test script
./scripts/generateTestdata.sh
```

If you encounter certificate validation issues, make sure your computer trusts the Root CA.

## Troubleshooting

### Check Logs
```bash
# On Raspberry Pi
docker-compose logs telemetrix
docker-compose logs mosquitto
```

### Check Database
```bash
./scripts/dbcheck.sh
```

### Verify MQTT Connection
Check that your devices can connect to MQTT using the correct certificates and credentials:
- Host: `dashboard.local` (or your Raspberry Pi's IP)
- Port: `8883`
- Protocol: `mqtt+ssl`
- Username: As configured in mosquitto_passwd
- Password: As configured in mosquitto_passwd
- CA Certificate: `rootCA.pem`

## Updating the Deployment

To update an existing deployment:

```bash
# Pull latest changes
git pull

# Re-run Ansible playbook
cd ansible
ansible-playbook -i inventory.yml deploy.yml --ask-vault-pass
```
