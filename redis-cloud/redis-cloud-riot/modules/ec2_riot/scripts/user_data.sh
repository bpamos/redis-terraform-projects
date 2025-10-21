#!/bin/bash

# =============================================================================
# EC2 RIOT Instance Setup Script
# Installs Redis OSS, RIOT-X, Docker, Prometheus, and Grafana
# =============================================================================

exec > /var/log/user-data.log 2>&1
set -e

# Configuration variables (injected by Terraform)
RIOTX_VERSION="${riotx_version}"
DOCKER_COMPOSE_VERSION="${docker_compose_version}"
ENABLE_OBSERVABILITY=${enable_observability}
RETRY_ATTEMPTS=5
RETRY_DELAY=10

echo "=== Starting EC2 RIOT instance setup ==="
echo "RIOTX Version: $RIOTX_VERSION"
echo "Docker Compose Version: $DOCKER_COMPOSE_VERSION"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

retry() {
  local n=0
  local cmd="$@"
  until [ $n -ge $RETRY_ATTEMPTS ]; do
    if $cmd; then
      return 0
    fi
    n=$((n+1))
    echo "Attempt $n failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  done
  echo "Command failed after $RETRY_ATTEMPTS attempts: $cmd"
  return 1
}

verify_service() {
  local service_name="$1"
  local test_command="$2"
  
  echo "Verifying $service_name..."
  if eval "$test_command"; then
    echo "✅ $service_name is working correctly"
    return 0
  else
    echo "❌ $service_name verification failed"
    return 1
  fi
}

# =============================================================================
# SYSTEM SETUP
# =============================================================================

echo "--- Updating system packages ---"
retry sudo apt-get update -y
retry sudo apt-get install -y redis-server curl unzip git docker.io

# =============================================================================
# REDIS OSS SETUP
# =============================================================================

echo "--- Setting up Redis OSS ---"
sudo systemctl enable redis-server
sudo systemctl start redis-server
sleep 5

verify_service "Redis OSS" "redis-cli ping | grep -q PONG" || exit 1

# =============================================================================
# RIOT-X INSTALLATION
# =============================================================================

echo "--- Installing RIOT-X $RIOTX_VERSION ---"
RIOTX_ZIP="riotx-standalone-$RIOTX_VERSION-linux-x86_64.zip"
RIOTX_URL="https://github.com/redis-field-engineering/riotx-dist/releases/download/v$RIOTX_VERSION/$RIOTX_ZIP"
RIOTX_DIR="/opt/riotx-standalone-$RIOTX_VERSION-linux-x86_64"

cd /opt
sudo curl -LO "$RIOTX_URL"
sudo unzip -o "$RIOTX_ZIP"
sudo chmod +x "$RIOTX_DIR/bin/riotx"
sudo ln -sf "$RIOTX_DIR/bin/riotx" /usr/local/bin/riotx

verify_service "RIOT-X" "riotx --version | grep -q 'riotx $RIOTX_VERSION'" || exit 1

# =============================================================================
# DOCKER SETUP
# =============================================================================

echo "--- Setting up Docker and Docker Compose ---"
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Install Docker Compose v2
COMPOSE_DIR="/home/ubuntu/.docker/cli-plugins"
COMPOSE_URL="https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64"

mkdir -p "$COMPOSE_DIR"
curl -SL "$COMPOSE_URL" -o "$COMPOSE_DIR/docker-compose"
chmod +x "$COMPOSE_DIR/docker-compose"
chown -R ubuntu:ubuntu /home/ubuntu/.docker

# =============================================================================
# OBSERVABILITY STACK SETUP (OPTIONAL)
# =============================================================================

if [ "$ENABLE_OBSERVABILITY" = "true" ]; then
  echo "--- Setting up Prometheus and Grafana ---"
  cd /home/ubuntu
  git clone https://github.com/redis-field-engineering/riotx-dist.git
  cd riotx-dist

  # Start observability stack with proper user context
  sudo -u ubuntu docker compose up -d

  # Wait for services to be ready
  echo "Waiting for observability stack to start..."
  sleep 30

  echo "=== Setup Complete ==="
  echo "📊 Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
  echo "📈 Grafana:    http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
  echo "🔧 RIOT-X:     Available via 'riotx' command"
  echo "📝 Logs:       /var/log/user-data.log"
else
  echo "=== Setup Complete ==="
  echo "🔧 RIOT-X:     Available via 'riotx' command"
  echo "📝 Logs:       /var/log/user-data.log"
  echo "ℹ️  Observability stack (Prometheus/Grafana) was disabled"
fi
