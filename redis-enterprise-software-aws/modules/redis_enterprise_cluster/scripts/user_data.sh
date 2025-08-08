#!/bin/bash
# =============================================================================
# REDIS ENTERPRISE SOFTWARE NODE BOOTSTRAP
# =============================================================================
# Lightweight bootstrap script that downloads and runs full installation
# =============================================================================

set -e

# Variables passed from Terraform
NODE_INDEX="${node_index}"
HOSTNAME="${hostname}"
RE_DOWNLOAD_URL="${re_download_url}"
CLUSTER_USERNAME="${cluster_username}"
CLUSTER_PASSWORD="${cluster_password}"
IS_PRIMARY_NODE="${is_primary_node}"
CLUSTER_FQDN="${cluster_fqdn}"
FLASH_ENABLED="${flash_enabled}"
RACK_AWARENESS="${rack_awareness}"

# =============================================================================
# LOGGING SETUP
# =============================================================================

exec > >(tee /var/log/redis-enterprise-bootstrap.log)
exec 2>&1

echo "Starting Redis Enterprise bootstrap - Node $${NODE_INDEX}"
echo "Timestamp: $(date)"

# =============================================================================
# CREATE FULL INSTALLATION SCRIPT
# =============================================================================

echo "Creating full installation script..."

cat > /tmp/redis_enterprise_install.sh << 'INSTALL_EOF'
#!/bin/bash
set -e

# Get parameters from environment or arguments
NODE_INDEX="$1"
HOSTNAME="$2"
RE_DOWNLOAD_URL="$3"
CLUSTER_USERNAME="$4"
CLUSTER_PASSWORD="$5"
IS_PRIMARY_NODE="$6"
CLUSTER_FQDN="$7"
FLASH_ENABLED="$8"
RACK_AWARENESS="$9"

echo "=== Redis Enterprise Installation Script ==="
echo "Node: $NODE_INDEX, Hostname: $HOSTNAME"
echo "Primary: $IS_PRIMARY_NODE, FQDN: $CLUSTER_FQDN"
echo "Timestamp: $(date)"

# System updates and prerequisites
echo "Installing prerequisites..."
apt-get update -y
apt-get install -y wget curl jq net-tools dnsutils htop

# Set hostname
echo "Setting hostname to $HOSTNAME..."
hostnamectl set-hostname "$HOSTNAME"
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# Wait for EBS volumes
echo "Waiting for EBS volumes..."
while [ ! -e /dev/nvme1n1 ] || [ ! -e /dev/nvme2n1 ]; do
    echo "Waiting for EBS volumes..."
    sleep 5
done

# Format and mount volumes
echo "Setting up EBS volumes..."
if ! blkid /dev/nvme1n1; then mkfs.xfs /dev/nvme1n1; fi
if ! blkid /dev/nvme2n1; then mkfs.xfs /dev/nvme2n1; fi

mkdir -p /var/opt/redislabs
mount /dev/nvme1n1 /var/opt/redislabs
mkdir -p /var/opt/redislabs/persist
mount /dev/nvme2n1 /var/opt/redislabs/persist

echo "/dev/nvme1n1 /var/opt/redislabs xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/nvme2n1 /var/opt/redislabs/persist xfs defaults,nofail 0 2" >> /etc/fstab

# System optimizations for Redis Enterprise
echo "Applying Redis Enterprise system optimizations..."
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
echo 'vm.overcommit_memory=1' >> /etc/sysctl.conf
echo 'vm.swappiness=1' >> /etc/sysctl.conf
sysctl -p

# Disable swap
swapoff -a 2>/dev/null || true
sed -i '/ swap / s/^/#/' /etc/fstab

# File descriptor limits
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
EOF

# Download and install Redis Enterprise
echo "Downloading Redis Enterprise from: $RE_DOWNLOAD_URL"
cd /tmp
wget -O redis-enterprise-package "$RE_DOWNLOAD_URL"

# Check if it's a .deb package or tar file
if file redis-enterprise-package | grep -q "Debian"; then
    echo "Installing Redis Enterprise .deb package..."
    sudo dpkg -i redis-enterprise-package || sudo apt-get install -f -y
else
    echo "Extracting Redis Enterprise tar package..."
    tar -xf redis-enterprise-package
    cd redislabs*
    sudo ./install.sh -y
fi

# Wait for services
echo "Waiting for Redis Enterprise services to start..."
sleep 60

if [ "$IS_PRIMARY_NODE" = "true" ]; then
    echo "Initializing primary node cluster..."
    # Wait for rladmin to be ready
    for i in {1..60}; do
        if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then break; fi
        echo "Waiting for rladmin... ($i/60)"
        sleep 10
    done
    
    # Create cluster
    CMD="sudo /opt/redislabs/bin/rladmin cluster create name $CLUSTER_FQDN username $CLUSTER_USERNAME password $CLUSTER_PASSWORD ephemeral_path /var/opt/redislabs persistent_path /var/opt/redislabs/persist"
    if [ "$RACK_AWARENESS" = "true" ]; then CMD="$CMD rack_aware"; fi
    if [ "$FLASH_ENABLED" = "true" ]; then CMD="$CMD flash_enabled"; fi
    
    echo "Executing: $CMD"
    eval "$CMD"
    echo "Cluster initialized successfully!"
    
else
    echo "Replica node ready. Use join script to add to cluster."
fi

# Create cluster management script
cat > /usr/local/bin/redis-cluster-join.sh << 'JOIN_SCRIPT'
#!/bin/bash
PRIMARY_IP="$1"
if [ -z "$PRIMARY_IP" ]; then
    echo "Usage: $0 <primary_node_ip>"
    exit 1
fi

echo "Joining cluster with primary node: $PRIMARY_IP"
for i in {1..60}; do
    if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then break; fi
    echo "Waiting for rladmin... ($i/60)"
    sleep 10
done

CMD="sudo /opt/redislabs/bin/rladmin cluster join nodes $PRIMARY_IP username $CLUSTER_USERNAME password $CLUSTER_PASSWORD ephemeral_path /var/opt/redislabs persistent_path /var/opt/redislabs/persist"
echo "Executing: $CMD"
eval "$CMD"
echo "Successfully joined cluster!"
JOIN_SCRIPT

chmod +x /usr/local/bin/redis-cluster-join.sh

# Status script
cat > /usr/local/bin/redis-status.sh << 'STATUS_SCRIPT'
#!/bin/bash
echo "=== Redis Enterprise Status ==="
sudo systemctl status rlec_supervisor --no-pager || true
echo ""
sudo /opt/redislabs/bin/rladmin status || echo "Cluster not configured"
echo ""
df -h /var/opt/redislabs* || true
STATUS_SCRIPT

chmod +x /usr/local/bin/redis-status.sh

echo "Redis Enterprise installation completed!"
echo "Node $NODE_INDEX is ready"
touch /tmp/redis-enterprise-installed
INSTALL_EOF

chmod +x /tmp/redis_enterprise_install.sh

# =============================================================================
# RUN INSTALLATION
# =============================================================================

echo "Running Redis Enterprise installation..."
/tmp/redis_enterprise_install.sh \
    "$${NODE_INDEX}" \
    "$${HOSTNAME}" \
    "$${RE_DOWNLOAD_URL}" \
    "$${CLUSTER_USERNAME}" \
    "$${CLUSTER_PASSWORD}" \
    "$${IS_PRIMARY_NODE}" \
    "$${CLUSTER_FQDN}" \
    "$${FLASH_ENABLED}" \
    "$${RACK_AWARENESS}"

echo "Bootstrap completed successfully!"
echo "Use 'sudo /usr/local/bin/redis-status.sh' to check status."
echo "Timestamp: $(date)"