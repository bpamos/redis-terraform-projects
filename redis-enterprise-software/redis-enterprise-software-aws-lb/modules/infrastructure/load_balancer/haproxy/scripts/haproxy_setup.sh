#!/bin/bash
# =============================================================================
# HAPROXY INSTALLATION AND SETUP SCRIPT
# =============================================================================
# Installs and configures HAProxy for Redis Enterprise load balancing
# =============================================================================

set -e

# Update system packages
apt-get update || yum update -y

# Install HAProxy based on the operating system
if command -v apt-get &> /dev/null; then
    echo "Installing HAProxy on Ubuntu/Debian..."
    apt-get install -y haproxy
elif command -v yum &> /dev/null; then
    echo "Installing HAProxy on RHEL/CentOS..."
    yum install -y haproxy
else
    echo "Unsupported operating system"
    exit 1
fi

# Enable and start HAProxy service
systemctl enable haproxy
systemctl start haproxy

# Create backup of original configuration
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

echo "HAProxy installation completed successfully"
echo "Service status:"
systemctl status haproxy --no-pager