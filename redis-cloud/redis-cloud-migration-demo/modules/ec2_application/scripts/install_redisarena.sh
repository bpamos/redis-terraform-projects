#!/bin/bash

# RedisArena Installation Script
# Sets up high-performance Redis gaming platform for migration demo

set -e

APP_DIR="/opt/redisarena"
SERVICE_USER="ubuntu"
LOG_FILE="/home/ubuntu/redisarena-install.log"

# Create log file in user directory to avoid permission issues
touch "$LOG_FILE"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Starting RedisArena installation..."

# Verify essential packages are available (installed by user-data)
log "🔍 Verifying essential packages are available..."
if ! command -v python3 >/dev/null 2>&1; then
    log "❌ python3 not found, installing..."
    sudo timeout 180 apt-get update -y
    sudo timeout 180 apt-get install -y python3 python3-pip python3-venv python3-dev build-essential || log "⚠️ Failed to install python3"
fi

if ! command -v pip3 >/dev/null 2>&1; then
    log "❌ pip3 not found, installing..."  
    sudo timeout 180 apt-get install -y python3-pip || log "⚠️ Failed to install pip3"
fi

# Ensure python3-venv is available
if ! python3 -m venv --help >/dev/null 2>&1; then
    log "❌ python3-venv not available, installing..."
    sudo timeout 180 apt-get install -y python3-venv || log "⚠️ Failed to install python3-venv"
fi

log "✅ Essential packages verified: python3, pip3, venv"

# Create application directory
log "📁 Creating application directory..."
sudo mkdir -p "$APP_DIR"
sudo chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"

# Create Python virtual environment
log "🔧 Setting up Python virtual environment..."
cd "$APP_DIR"

# Try to create venv, install python3-venv if it fails
if ! python3 -m venv venv 2>/dev/null; then
    log "❌ venv creation failed, installing python3-venv..."
    sudo apt-get update -y
    sudo apt-get install -y python3.10-venv python3-venv
    
    # Try again after installing
    if ! python3 -m venv venv; then
        log "❌ Critical error: Cannot create Python virtual environment"
        exit 1
    fi
fi

# Verify venv was created successfully
if [ ! -f venv/bin/activate ]; then
    log "❌ Critical error: Virtual environment not created properly"
    exit 1
fi

source venv/bin/activate
log "✅ Python virtual environment activated"

# Upgrade pip and install Python packages with timeout protection
log "📦 Installing Python dependencies..."
timeout 300 pip install --upgrade pip setuptools wheel || log "⚠️ pip upgrade may have failed"
timeout 300 pip install -r /tmp/redisarena/requirements.txt || {
    log "❌ pip install failed, trying alternative approach..."
    # Try installing packages individually
    pip install flask==3.0.0 redis==5.0.1 python-dotenv==1.0.0 || log "⚠️ Some Python packages may have failed"
}

# Copy application files
log "📋 Installing application files..."
cp /tmp/redisarena/redis_arena.py "$APP_DIR/"
chmod +x "$APP_DIR/redis_arena.py"

# Copy templates and static directories
log "📋 Installing Flask templates and static assets..."
if [ -d "/tmp/redisarena/templates" ]; then
    cp -r /tmp/redisarena/templates "$APP_DIR/"
    log "✅ Templates directory copied"
else
    log "⚠️ Templates directory not found"
fi

if [ -d "/tmp/redisarena/static" ]; then
    cp -r /tmp/redisarena/static "$APP_DIR/"
    log "✅ Static assets directory copied"
else
    log "⚠️ Static assets directory not found"
fi

# Create environment file template
log "⚙️ Creating environment configuration..."
cat > "$APP_DIR/.env" << 'EOF'
# RedisArena Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Application Settings
FLASK_ENV=production
SECRET_KEY=redis-arena-demo-key-change-in-production

# Performance Settings
REDIS_POOL_MAX_CONNECTIONS=20
HEALTH_CHECK_INTERVAL=30

# Demo Settings
AUTO_START_SIMULATION=true
EOF

chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/.env"

# Create systemd service file
log "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/redisarena.service > /dev/null << EOF
[Unit]
Description=RedisArena - High-Performance Gaming Platform
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/redis_arena.py
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=redisarena

# Security settings (relaxed for demo functionality)
NoNewPrivileges=false
PrivateDevices=false
ProtectHome=false
ProtectSystem=false
ReadWritePaths=$APP_DIR /tmp /var/log /home/ubuntu /opt/cutover-ui

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Create log rotation configuration
log "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/redisarena > /dev/null << EOF
/var/log/redisarena*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    su $SERVICE_USER $SERVICE_USER
}
EOF

# Create health check script
log "🏥 Creating health check script..."
cat > "$APP_DIR/health_check.sh" << 'EOF'
#!/bin/bash

# RedisArena Health Check Script

APP_URL="http://localhost:5000/api/status"
TIMEOUT=10

# Check if application is responding
if /usr/bin/curl -f -s --max-time $TIMEOUT "$APP_URL" > /dev/null; then
    echo "✅ RedisArena is healthy"
    exit 0
else
    echo "❌ RedisArena is unhealthy"
    exit 1
fi
EOF

chmod +x "$APP_DIR/health_check.sh"
chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/health_check.sh"

# Create data loading script
log "📊 Creating data loading script..."
cat > "$APP_DIR/load_data.sh" << 'EOF'
#!/bin/bash

# Load sample data into RedisArena

echo "🔄 Loading sample data (this may take 5-10 minutes)..."
/usr/bin/curl -X POST http://localhost:5000/api/load-data

echo "✅ Data loading initiated. Check the web interface for progress."
EOF

chmod +x "$APP_DIR/load_data.sh"
chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/load_data.sh"

# Set up monitoring script
log "📊 Creating monitoring script..."
cat > "$APP_DIR/monitor.sh" << 'EOF'
#!/bin/bash

# RedisArena Monitoring Script

echo "=== RedisArena System Status ==="
echo

# Service status
echo "🔧 Service Status:"
/usr/bin/systemctl is-active redisarena || echo "Service not running"
echo

# Process information
echo "⚡ Process Info:"
/usr/bin/ps aux | /usr/bin/grep redis_arena.py | /usr/bin/grep -v grep || echo "No process found"
echo

# Port status
echo "🌐 Port Status:"
/usr/bin/ss -tulpn | /usr/bin/grep :5000 || echo "Port 5000 not listening"
echo

# Redis connection
echo "🔗 Redis Connection:"
if /usr/bin/command -v redis-cli >/dev/null 2>&1; then
    REDIS_HOST=$(/usr/bin/grep REDIS_HOST /opt/redisarena/.env | /usr/bin/cut -d'=' -f2)
    REDIS_PORT=$(/usr/bin/grep REDIS_PORT /opt/redisarena/.env | /usr/bin/cut -d'=' -f2)
    /usr/bin/redis-cli -h ${REDIS_HOST:-localhost} -p ${REDIS_PORT:-6379} ping || echo "Redis connection failed"
else
    echo "redis-cli not available"
fi
echo

# System resources
echo "💻 System Resources:"
/usr/bin/free -h | /usr/bin/head -2
/usr/bin/df -h / | /usr/bin/tail -1
echo

# Recent logs
echo "📝 Recent Logs (last 10 lines):"
/usr/bin/journalctl -u redisarena --no-pager -n 10 || echo "No service logs available"
EOF

chmod +x "$APP_DIR/monitor.sh"
chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/monitor.sh"

# Reload systemd and enable service
log "🔄 Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable redisarena

# Create startup script for easy management
log "🚀 Creating management scripts..."
cat > "$APP_DIR/manage.sh" << 'EOF'
#!/bin/bash

# RedisArena Management Script

case "$1" in
    start)
        echo "🚀 Starting RedisArena..."
        /usr/bin/sudo /usr/bin/systemctl start redisarena
        /usr/bin/sleep 3
        ./health_check.sh
        ;;
    stop)
        echo "⏹️ Stopping RedisArena..."
        /usr/bin/sudo /usr/bin/systemctl stop redisarena
        ;;
    restart)
        echo "♻️ Restarting RedisArena..."
        /usr/bin/sudo /usr/bin/systemctl restart redisarena  
        /usr/bin/sleep 3
        ./health_check.sh
        ;;
    status)
        ./monitor.sh
        ;;
    logs)
        echo "📝 Recent logs:"
        /usr/bin/journalctl -u redisarena -f
        ;;
    health)
        ./health_check.sh
        ;;
    load-data)
        ./load_data.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|health|load-data}"
        exit 1
        ;;
esac
EOF

chmod +x "$APP_DIR/manage.sh"
chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/manage.sh"

# Set proper ownership for all files
log "🔒 Setting file permissions..."
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"

# Install completion marker
log "✅ RedisArena installation completed successfully!"

# Display next steps
cat << 'EOF'

🎉 RedisArena Installation Complete!

Next Steps:
1. Configure Redis connection in /opt/redisarena/.env
2. Start the service: /opt/redisarena/manage.sh start
3. Check status: /opt/redisarena/manage.sh status  
4. Load sample data: /opt/redisarena/manage.sh load-data
5. Access web interface: http://<server-ip>:5000

Management Commands:
- /opt/redisarena/manage.sh {start|stop|restart|status|logs|health|load-data}
- /opt/redisarena/monitor.sh (detailed system status)

Log Files:
- Installation: /home/ubuntu/redisarena-install.log
- Application: journalctl -u redisarena

EOF

log "🎮 RedisArena is ready for gaming!"