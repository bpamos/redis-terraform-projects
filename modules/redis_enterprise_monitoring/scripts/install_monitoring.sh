#!/bin/bash
# =============================================================================
# REDIS ENTERPRISE MONITORING STACK INSTALLATION
# =============================================================================
# Installs Prometheus and Grafana on Ubuntu for Redis Enterprise monitoring
# Usage: ./install_monitoring.sh <grafana_user> <grafana_pass> <anon_access> \
#        <grafana_port> <prometheus_port> <retention_days> <install_dashboards> \
#        <github_repo> <github_branch>
# =============================================================================

set -e

# Arguments
GRAFANA_ADMIN_USER="${1:-admin}"
GRAFANA_ADMIN_PASSWORD="${2:-admin}"
GRAFANA_ANONYMOUS_ACCESS="${3:-true}"
GRAFANA_PORT="${4:-3000}"
PROMETHEUS_PORT="${5:-9090}"
PROMETHEUS_RETENTION_DAYS="${6:-15}"
INSTALL_DASHBOARDS="${7:-true}"
GITHUB_REPO="${8:-redis-field-engineering/redis-enterprise-observability}"
GITHUB_BRANCH="${9:-main}"

LOG_FILE="/var/log/monitoring-install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================================="
echo "Installing Redis Enterprise Monitoring Stack"
echo "==================================================================="
echo "Grafana Port: $GRAFANA_PORT"
echo "Prometheus Port: $PROMETHEUS_PORT"
echo "Retention: $PROMETHEUS_RETENTION_DAYS days"
echo "Anonymous Access: $GRAFANA_ANONYMOUS_ACCESS"
echo "Install Dashboards: $INSTALL_DASHBOARDS"
echo "==================================================================="

# =============================================================================
# SYSTEM PREPARATION
# =============================================================================

echo "--- Updating system packages ---"
apt-get update -y
apt-get install -y curl wget gnupg2 apt-transport-https software-properties-common

# =============================================================================
# PROMETHEUS INSTALLATION
# =============================================================================

echo "--- Installing Prometheus ---"

# Create prometheus user and directories
useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
mkdir -p /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Download latest Prometheus
PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
echo "Downloading Prometheus v$PROMETHEUS_VERSION..."

cd /tmp
wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
tar xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
cd "prometheus-${PROMETHEUS_VERSION}.linux-amd64"

# Install binaries
cp prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Install console templates (if they exist - removed in Prometheus 3.x)
[ -d consoles ] && cp -r consoles /etc/prometheus/
[ -d console_libraries ] && cp -r console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus

# Clean up
cd /tmp
rm -rf "prometheus-${PROMETHEUS_VERSION}.linux-amd64" "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

# Copy Prometheus configuration
cp /tmp/prometheus.yml /etc/prometheus/prometheus.yml
chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Build Prometheus ExecStart command (console paths only if they exist)
PROM_EXEC="/usr/local/bin/prometheus"
PROM_EXEC="$PROM_EXEC --config.file=/etc/prometheus/prometheus.yml"
PROM_EXEC="$PROM_EXEC --storage.tsdb.path=/var/lib/prometheus/"
PROM_EXEC="$PROM_EXEC --storage.tsdb.retention.time=${PROMETHEUS_RETENTION_DAYS}d"
PROM_EXEC="$PROM_EXEC --web.listen-address=:${PROMETHEUS_PORT}"
PROM_EXEC="$PROM_EXEC --web.enable-lifecycle"

# Create Prometheus systemd service
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=${PROM_EXEC}

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "--- Starting Prometheus ---"
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Verify Prometheus is running
sleep 3
if systemctl is-active --quiet prometheus; then
    echo "✅ Prometheus started successfully on port $PROMETHEUS_PORT"
else
    echo "❌ Prometheus failed to start"
    journalctl -u prometheus --no-pager -n 20
    exit 1
fi

# =============================================================================
# GRAFANA INSTALLATION
# =============================================================================

echo "--- Installing Grafana ---"

# Add Grafana repository
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list

apt-get update -y
apt-get install -y grafana

# =============================================================================
# GRAFANA CONFIGURATION
# =============================================================================

echo "--- Configuring Grafana ---"

# Update Grafana config
GRAFANA_INI="/etc/grafana/grafana.ini"

# Set HTTP port
sed -i "s/^;http_port = 3000/http_port = ${GRAFANA_PORT}/" "$GRAFANA_INI"
sed -i "s/^http_port = 3000/http_port = ${GRAFANA_PORT}/" "$GRAFANA_INI"

# Set admin credentials
sed -i "s/^;admin_user = admin/admin_user = ${GRAFANA_ADMIN_USER}/" "$GRAFANA_INI"
sed -i "s/^;admin_password = admin/admin_password = ${GRAFANA_ADMIN_PASSWORD}/" "$GRAFANA_INI"

# Configure anonymous access
if [ "$GRAFANA_ANONYMOUS_ACCESS" = "true" ]; then
    # Find the [auth.anonymous] section and update it
    sed -i '/^\[auth.anonymous\]/,/^\[/ {
        s/^;enabled = false/enabled = true/
        s/^enabled = false/enabled = true/
        s/^;org_role = Viewer/org_role = Viewer/
    }' "$GRAFANA_INI"
fi

# Disable login form for anonymous users (optional - makes dashboards immediately visible)
sed -i 's/^;disable_login_form = false/disable_login_form = false/' "$GRAFANA_INI"

# =============================================================================
# GRAFANA PROVISIONING - DATASOURCE
# =============================================================================

echo "--- Setting up Grafana provisioning ---"

# Copy datasource configuration
mkdir -p /etc/grafana/provisioning/datasources
cp /tmp/grafana-datasource.yml /etc/grafana/provisioning/datasources/prometheus.yml
chown grafana:grafana /etc/grafana/provisioning/datasources/prometheus.yml

# =============================================================================
# GRAFANA PROVISIONING - DASHBOARD PROVIDER
# =============================================================================

mkdir -p /etc/grafana/provisioning/dashboards
cp /tmp/grafana-dashboard-provider.yml /etc/grafana/provisioning/dashboards/redis-enterprise.yml
chown grafana:grafana /etc/grafana/provisioning/dashboards/redis-enterprise.yml

# =============================================================================
# DOWNLOAD REDIS ENTERPRISE DASHBOARDS
# =============================================================================

if [ "$INSTALL_DASHBOARDS" = "true" ]; then
    echo "--- Downloading Redis Enterprise Ops Dashboards ---"

    DASHBOARD_DIR="/var/lib/grafana/dashboards/redis-enterprise"
    mkdir -p "$DASHBOARD_DIR"

    # Dashboard files to download
    DASHBOARDS=(
        "cluster.json"
        "database.json"
        "node.json"
        "shard.json"
        "latency.json"
        "qps.json"
        "active-active.json"
    )

    BASE_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/grafana_v2/dashboards/grafana_v9-11/software/ops"

    for dashboard in "${DASHBOARDS[@]}"; do
        echo "Downloading $dashboard..."
        if wget -q -O "${DASHBOARD_DIR}/${dashboard}" "${BASE_URL}/${dashboard}"; then
            # Replace datasource UID placeholder with our Prometheus datasource
            # The dashboards use ${DS_PROMETHEUS} which needs to be replaced with actual UID
            sed -i 's/\${DS_PROMETHEUS}/prometheus/g' "${DASHBOARD_DIR}/${dashboard}"
            echo "  ✅ $dashboard downloaded and configured"
        else
            echo "  ⚠️ Failed to download $dashboard (may not exist)"
        fi
    done

    # Set permissions
    chown -R grafana:grafana "$DASHBOARD_DIR"

    echo "✅ Dashboards installed to $DASHBOARD_DIR"
fi

# =============================================================================
# START GRAFANA
# =============================================================================

echo "--- Starting Grafana ---"
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Verify Grafana is running
sleep 5
if systemctl is-active --quiet grafana-server; then
    echo "✅ Grafana started successfully on port $GRAFANA_PORT"
else
    echo "❌ Grafana failed to start"
    journalctl -u grafana-server --no-pager -n 20
    exit 1
fi

# =============================================================================
# CREATE HELPER SCRIPTS
# =============================================================================

echo "--- Creating helper scripts ---"

# Script to check Prometheus targets
cat > /home/ubuntu/check-prometheus-targets.sh << 'SCRIPT'
#!/bin/bash
echo "Prometheus Targets Status:"
echo "=========================="
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health) - \(.lastScrape)"'
SCRIPT
chmod +x /home/ubuntu/check-prometheus-targets.sh
chown ubuntu:ubuntu /home/ubuntu/check-prometheus-targets.sh

# Script to reload Prometheus config
cat > /home/ubuntu/reload-prometheus.sh << 'SCRIPT'
#!/bin/bash
echo "Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload
echo ""
echo "Done. Check targets with: ./check-prometheus-targets.sh"
SCRIPT
chmod +x /home/ubuntu/reload-prometheus.sh
chown ubuntu:ubuntu /home/ubuntu/reload-prometheus.sh

# Script to check service status
cat > /home/ubuntu/monitoring-status.sh << 'SCRIPT'
#!/bin/bash
echo "==================================================================="
echo "Redis Enterprise Monitoring Status"
echo "==================================================================="
echo ""
echo "Prometheus:"
systemctl status prometheus --no-pager -l | head -5
echo ""
echo "Grafana:"
systemctl status grafana-server --no-pager -l | head -5
echo ""
echo "==================================================================="
echo "Endpoints:"
BASTION_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
echo "  Prometheus: http://${BASTION_IP}:9090"
echo "  Grafana:    http://${BASTION_IP}:3000"
echo "==================================================================="
SCRIPT
chmod +x /home/ubuntu/monitoring-status.sh
chown ubuntu:ubuntu /home/ubuntu/monitoring-status.sh

# =============================================================================
# INSTALLATION COMPLETE
# =============================================================================

echo ""
echo "==================================================================="
echo "Redis Enterprise Monitoring Stack Installation Complete"
echo "==================================================================="
echo ""
echo "Services:"
echo "  ✅ Prometheus: http://localhost:${PROMETHEUS_PORT}"
echo "  ✅ Grafana:    http://localhost:${GRAFANA_PORT}"
echo ""
echo "Grafana Credentials:"
echo "  Username: ${GRAFANA_ADMIN_USER}"
echo "  Password: ${GRAFANA_ADMIN_PASSWORD}"
[ "$GRAFANA_ANONYMOUS_ACCESS" = "true" ] && echo "  (Anonymous viewing enabled)"
echo ""
echo "Helper Scripts:"
echo "  ./monitoring-status.sh        - Check service status"
echo "  ./check-prometheus-targets.sh - View Prometheus scrape targets"
echo "  ./reload-prometheus.sh        - Reload Prometheus config"
echo ""
echo "Configuration Files:"
echo "  Prometheus: /etc/prometheus/prometheus.yml"
echo "  Grafana:    /etc/grafana/grafana.ini"
echo "  Dashboards: /var/lib/grafana/dashboards/redis-enterprise/"
echo ""
echo "Logs:"
echo "  journalctl -u prometheus -f"
echo "  journalctl -u grafana-server -f"
echo "  $LOG_FILE"
echo ""
echo "==================================================================="
