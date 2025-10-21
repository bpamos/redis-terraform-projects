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

# Download and import official Redis Cloud operational dashboards
echo "Downloading official Redis Cloud operational dashboards..."
mkdir -p /home/ubuntu/dashboards

# Base URL for official Redis Cloud operational dashboards
BASE_URL="https://raw.githubusercontent.com/redis-field-engineering/redis-enterprise-observability/main/grafana_v2/dashboards/grafana_v9-11/cloud/ops"

# Download all official operational dashboards
echo "Downloading Active-Active dashboard..."
curl -s "$BASE_URL/active-active.json" > /home/ubuntu/dashboards/active-active.json

echo "Downloading Cluster dashboard..."
curl -s "$BASE_URL/cluster.json" > /home/ubuntu/dashboards/cluster.json

echo "Downloading Database dashboard..."
curl -s "$BASE_URL/database.json" > /home/ubuntu/dashboards/database.json

echo "Downloading Latency dashboard..."
curl -s "$BASE_URL/latency.json" > /home/ubuntu/dashboards/latency.json

echo "Downloading Node dashboard..."
curl -s "$BASE_URL/node.json" > /home/ubuntu/dashboards/node.json

echo "Downloading QPS dashboard..."
curl -s "$BASE_URL/qps.json" > /home/ubuntu/dashboards/qps.json

echo "Downloading Shard dashboard..."
curl -s "$BASE_URL/shard.json" > /home/ubuntu/dashboards/shard.json

# Replace DS_PROMETHEUS variable with redis-cloud datasource name
echo "Configuring datasource references..."
for file in /home/ubuntu/dashboards/*.json; do
    sed -i 's/\${DS_PROMETHEUS}/redis-cloud/g' "$file"
done

# Wait for Grafana to be fully ready
echo "Waiting for Grafana to be ready for API calls..."
sleep 20

# Import all official dashboards via Grafana API
echo "Importing all official Redis Cloud operational dashboards..."
for dashboard in active-active cluster database latency node qps shard; do
    echo "Importing $dashboard dashboard..."
    #  Create import payload using python to ensure valid JSON
    python3 -c "
import json
with open('/home/ubuntu/dashboards/$dashboard.json', 'r') as f:
    dashboard_data = json.load(f)
import_payload = {'dashboard': dashboard_data, 'overwrite': True}
with open('/tmp/import-$dashboard.json', 'w') as f:
    json.dump(import_payload, f)
"

    # Use curl to import dashboard from file
    result=$(curl -s -X POST http://admin:admin@localhost:3000/api/dashboards/db \
        -H "Content-Type: application/json" \
        -d @/tmp/import-$dashboard.json)

    # Check if import was successful
    if echo "$result" | grep -q '"status":"success"'; then
        echo "✅ $dashboard dashboard imported successfully"
    else
        echo "⚠️ $dashboard dashboard import may have failed"
    fi
done

# Verify dashboards were imported
DASHBOARD_COUNT=$(curl -s http://admin:admin@localhost:3000/api/search | grep -c '"title"')
echo "✅ Imported $DASHBOARD_COUNT dashboards successfully"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo ""
echo "=== Redis Cloud Observability Setup Complete ==="
echo "📊 Prometheus: http://$PUBLIC_IP:9090"
echo "📈 Grafana:    http://$PUBLIC_IP:3000 (admin/admin)"
echo ""
echo "✅ Official Redis Cloud Operational Dashboards:"
echo "   - Active-Active Dashboard - Redis Cloud Active-Active replication metrics"
echo "   - Cluster Dashboard - Redis Cloud cluster-level performance and health metrics"
echo "   - Database Dashboard - Redis Cloud database performance and operations metrics"
echo "   - Latency Dashboard - Redis Cloud latency and response time metrics"
echo "   - Node Dashboard - Redis Cloud node-level resource and performance metrics"
echo "   - QPS Dashboard - Redis Cloud queries per second and throughput metrics"
echo "   - Shard Dashboard - Redis Cloud shard-level performance and distribution metrics"
echo ""
echo "📋 Source: Official Redis Field Engineering operational dashboards"
echo "📚 Documentation: https://github.com/redis-field-engineering/redis-enterprise-observability"
echo ""
echo "Redis Cloud monitoring is ready! 🚀"
echo ""