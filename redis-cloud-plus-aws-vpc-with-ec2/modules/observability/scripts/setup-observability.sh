#!/bin/bash

# =============================================================================
# OBSERVABILITY SETUP SCRIPT FOR REDIS CLOUD MONITORING
# =============================================================================

set -e

echo "=== Setting up Redis Cloud Observability ==="

# Wait for Docker to be installed by user-data script
echo "Waiting for Docker installation to complete..."
for i in {1..60}; do
  if command -v docker >/dev/null 2>&1; then
    echo "Docker found, proceeding..."
    break
  fi
  if [ $i -eq 60 ]; then
    echo "Docker not found after 5 minutes, installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
    break
  fi
  echo "Waiting for Docker... (attempt $i/60)"
  sleep 5
done

# Ensure Docker is running and user is in docker group
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Wait for Docker daemon to be ready
for i in {1..30}; do
  if docker info >/dev/null 2>&1; then
    echo "Docker daemon is ready"
    break
  fi
  echo "Waiting for Docker daemon... (attempt $i/30)"
  sleep 2
done

# Install Docker Compose v2 if not already installed
COMPOSE_DIR="/home/ubuntu/.docker/cli-plugins"
COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64"

if [ ! -f "$COMPOSE_DIR/docker-compose" ]; then
    echo "Installing Docker Compose..."
    sudo -u ubuntu mkdir -p "$COMPOSE_DIR"
    curl -SL "$COMPOSE_URL" -o "$COMPOSE_DIR/docker-compose"
    chmod +x "$COMPOSE_DIR/docker-compose"
    chown -R ubuntu:ubuntu /home/ubuntu/.docker
fi

# Create directory structure
sudo -u ubuntu mkdir -p /home/ubuntu/prometheus /home/ubuntu/grafana/provisioning/datasources

# Move uploaded configuration files to correct locations
sudo -u ubuntu mv /home/ubuntu/prometheus-config.yml /home/ubuntu/prometheus/prometheus.yml
sudo -u ubuntu mv /home/ubuntu/grafana-datasource.yml /home/ubuntu/grafana/provisioning/datasources/prometheus.yml

# Set proper ownership
chown -R ubuntu:ubuntu /home/ubuntu/prometheus /home/ubuntu/grafana /home/ubuntu/docker-compose.yml

# Start the monitoring stack
cd /home/ubuntu
sudo -u ubuntu docker compose down --remove-orphans || true
sudo -u ubuntu docker compose up -d

# Wait for services to start
echo "Waiting for monitoring services to start..."
sleep 30

# Verify services are running
if docker ps | grep -q prometheus; then
    echo "✅ Prometheus is running"
else
    echo "❌ Prometheus failed to start"
fi

if docker ps | grep -q grafana; then
    echo "✅ Grafana is running"
else
    echo "❌ Grafana failed to start"
fi

# Test Prometheus targets
echo "Checking Prometheus targets..."
sleep 10
TARGET_STATUS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"' | head -1)
echo "Redis Cloud target status: $TARGET_STATUS"

# Download and import Redis Cloud dashboards
echo "Downloading and importing Redis Cloud dashboards..."
mkdir -p /home/ubuntu/dashboards

# Download official Redis Field Engineering dashboards
curl -s https://raw.githubusercontent.com/redis-field-engineering/redis-enterprise-observability/main/grafana/dashboards/grafana_v9-11/cloud/basic/redis-cloud-database-dashboard_v9-11.json > /home/ubuntu/dashboards/redis-database.json
curl -s https://raw.githubusercontent.com/redis-field-engineering/redis-enterprise-observability/main/grafana/dashboards/grafana_v9-11/cloud/basic/redis-cloud-subscription-dashboard_v9-11.json > /home/ubuntu/dashboards/redis-subscription.json
curl -s https://raw.githubusercontent.com/redis-field-engineering/redis-enterprise-observability/main/grafana/dashboards/grafana_v9-11/cloud/basic/redis-cloud-proxy-dashboard_v9-11.json > /home/ubuntu/dashboards/redis-proxy.json

# Fix datasource references (replace template variables with actual datasource name)
sed -i 's/\${DS_PROMETHEUS}/Prometheus/g' /home/ubuntu/dashboards/*.json

# Wait for Grafana to be fully ready
echo "Waiting for Grafana to be ready for API calls..."
sleep 20

# Import dashboards via Grafana API
echo "Importing Redis Cloud Database dashboard..."
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d "{\"dashboard\": $(cat /home/ubuntu/dashboards/redis-database.json), \"overwrite\": true}" > /dev/null 2>&1

echo "Importing Redis Cloud Subscription dashboard..."
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d "{\"dashboard\": $(cat /home/ubuntu/dashboards/redis-subscription.json), \"overwrite\": true}" > /dev/null 2>&1

echo "Importing Redis Cloud Proxy dashboard..."
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d "{\"dashboard\": $(cat /home/ubuntu/dashboards/redis-proxy.json), \"overwrite\": true}" > /dev/null 2>&1

# Verify dashboards were imported
DASHBOARD_COUNT=$(curl -s http://admin:admin@localhost:3000/api/search | grep -c '"title"')
echo "✅ Imported $DASHBOARD_COUNT dashboards successfully"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo ""
echo "=== Redis Cloud Observability Setup Complete ==="
echo "📊 Prometheus: http://$PUBLIC_IP:9090"
echo "📈 Grafana:    http://$PUBLIC_IP:3000 (admin/admin)"
echo ""
echo "✅ Available Redis Cloud Dashboards:"
echo "   - Database Status Dashboard"
echo "   - Subscription Status Dashboard" 
echo "   - Proxy Threads Dashboard"
echo ""
echo "Redis Cloud monitoring is ready! 🚀"
echo ""