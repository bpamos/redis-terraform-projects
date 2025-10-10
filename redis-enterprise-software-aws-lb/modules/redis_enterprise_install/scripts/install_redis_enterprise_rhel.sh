#!/bin/bash
# =============================================================================
# REDIS ENTERPRISE INSTALLATION SCRIPT - RHEL/CentOS
# =============================================================================
# Called by Terraform null_resource provisioner
# =============================================================================

set -e

# Parameters from Terraform
RE_DOWNLOAD_URL="$1"
NODE_INDEX="$2"
IS_PRIMARY_NODE="$3"
CLUSTER_FQDN="$4"
CLUSTER_USERNAME="$5"
CLUSTER_PASSWORD="$6"
FLASH_ENABLED="$7"
RACK_AWARENESS="$8"
PLATFORM="$9"

# Logging
exec > >(tee /var/log/redis-enterprise-install.log)
exec 2>&1

echo "=== Redis Enterprise Installation (RHEL) ==="
echo "Node: $NODE_INDEX, Primary: $IS_PRIMARY_NODE"
echo "FQDN: $CLUSTER_FQDN"
echo "Download URL: $RE_DOWNLOAD_URL"
echo "Platform: $PLATFORM"
echo "Timestamp: $(date)"

# Verify basic setup completed
if [ ! -f /tmp/basic-setup-complete ]; then
    echo "ERROR: Basic setup not completed"
    exit 1
fi

# Verify EBS volumes are mounted
if ! mountpoint -q /var/opt/redislabs; then
    echo "ERROR: Redis data volume not mounted"
    exit 1
fi

if ! mountpoint -q /var/opt/redislabs/persist; then
    echo "ERROR: Redis persist volume not mounted"  
    exit 1
fi

echo "✓ Prerequisites verified"

# =============================================================================
# RHEL-SPECIFIC SYSTEM OPTIMIZATIONS FOR REDIS ENTERPRISE
# =============================================================================

echo "Applying Redis Enterprise system optimizations for RHEL..."

# Disable transparent huge pages (required)
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Make THP settings persistent
sudo tee /etc/systemd/system/disable-thp.service > /dev/null << 'EOF'
[Unit]
Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo never > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable disable-thp.service
sudo systemctl start disable-thp.service

# Memory and swap settings
echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Disable swap
sudo swapoff -a 2>/dev/null || true
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# File descriptor limits
sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF

# RHEL-specific firewall configuration
echo "Configuring firewall for Redis Enterprise..."
if command -v firewall-cmd &> /dev/null; then
    # Redis Enterprise cluster communication
    sudo firewall-cmd --permanent --add-port=8001/tcp --add-port=8070-8071/tcp
    sudo firewall-cmd --permanent --add-port=9081/tcp --add-port=9443/tcp
    sudo firewall-cmd --permanent --add-port=8443/tcp --add-port=8080/tcp
    sudo firewall-cmd --permanent --add-port=53/tcp --add-port=53/udp
    sudo firewall-cmd --permanent --add-port=5353/tcp --add-port=5353/udp
    # Database ports (10000-19999)
    sudo firewall-cmd --permanent --add-port=10000-19999/tcp
    # Reload firewall
    sudo firewall-cmd --reload
    echo "✓ Firewall configured"
else
    echo "WARNING: firewall-cmd not found, firewall configuration skipped"
fi

# RHEL/CentOS specific packages
echo "Installing required packages..."
sudo dnf update -y
sudo dnf install -y wget curl nc bind-utils

echo "✓ System optimizations applied"

# =============================================================================
# DOWNLOAD AND INSTALL REDIS ENTERPRISE
# =============================================================================

echo "Downloading Redis Enterprise..."
cd /tmp

# Download with retry logic (skip if already exists)
if [ -f redis-enterprise-package ]; then
    echo "✓ Redis Enterprise package already downloaded"
else
    for i in {1..3}; do
        if wget -O redis-enterprise-package "$RE_DOWNLOAD_URL"; then
            echo "✓ Download successful"
            break
        else
            echo "Download attempt $i failed, retrying..."
            sleep 10
            if [ $i -eq 3 ]; then
                echo "ERROR: Failed to download after 3 attempts"
                exit 1
            fi
        fi
    done
fi

# Install Redis Enterprise from tar archive (RHEL uses tar packages)
echo "Installing Redis Enterprise..."
FILE_TYPE=$(file redis-enterprise-package)
if echo "$FILE_TYPE" | grep -q "tar"; then
    echo "Extracting Redis Enterprise tar archive..."
    tar -xf redis-enterprise-package
    
    # Use the included install.sh script which handles proper setup
    if [ -f install.sh ]; then
        echo "Running official Redis Enterprise installer..."
        sudo ./install.sh -y
    else
        echo "ERROR: install.sh not found in package"
        ls -la
        exit 1
    fi
else
    echo "ERROR: Expected tar archive for RHEL platform, got: $FILE_TYPE"
    exit 1
fi

echo "✓ Redis Enterprise installed"

# =============================================================================
# POST-INSTALLATION SETUP
# =============================================================================

echo "Waiting for Redis Enterprise services to start..."
sleep 30

# Verify installation
if ! sudo systemctl is-active --quiet rlec_supervisor; then
    echo "Starting Redis Enterprise supervisor..."
    sudo systemctl start rlec_supervisor
    sleep 30
fi

# Check if supervisor is running (don't wait for cluster readiness)
if sudo systemctl is-active --quiet rlec_supervisor; then
    echo "✓ Redis Enterprise supervisor is running"
else
    echo "WARNING: Redis Enterprise supervisor is not running"
    sudo systemctl status rlec_supervisor --no-pager
fi

# Create simple status script
echo "Creating management scripts..."

sudo tee /usr/local/bin/redis-status.sh > /dev/null << 'STATUS_EOF'
#!/bin/bash
echo "=== Redis Enterprise Status ==="
echo "Service Status:"
sudo systemctl status rlec_supervisor --no-pager || true
echo ""
echo "Cluster Status:"
sudo /opt/redislabs/bin/rladmin status || echo "Cluster not configured"
echo ""
echo "Storage Usage:"
df -h /var/opt/redislabs* || true
echo ""
echo "Firewall Status:"
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --list-all || true
fi
echo "================================"
STATUS_EOF

sudo chmod +x /usr/local/bin/redis-status.sh

# Create installation marker
touch /tmp/redis-enterprise-installed

echo "✓ Redis Enterprise software installation completed!"
echo "Node $NODE_INDEX installation finished"
echo "Use 'sudo /usr/local/bin/redis-status.sh' to check status"
echo "Timestamp: $(date)"