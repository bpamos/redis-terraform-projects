#!/bin/bash
# =============================================================================
# BASIC SYSTEM SETUP (User Data)
# =============================================================================
# Minimal setup that fits within user_data limits
# =============================================================================

set -e

exec > >(tee /var/log/basic-setup.log)
exec 2>&1

echo "Starting basic system setup - $(date)"

# Set hostname
echo "Setting hostname to ${hostname}..."
hostnamectl set-hostname "${hostname}"
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install essential packages
echo "Installing prerequisites..."
apt-get update -y
apt-get install -y wget curl jq net-tools dnsutils htop xfsprogs chrony

# Configure and start Chrony for time synchronization (required for Active-Active)
echo "Configuring Chrony for time synchronization..."
systemctl enable chrony
systemctl start chrony

# Stop systemd-resolved to free port 53 for Redis Enterprise DNS
echo "Stopping systemd-resolved for Redis Enterprise DNS..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Wait for EBS volumes to be attached
echo "Waiting for EBS volumes..."
while [ ! -e /dev/nvme1n1 ] || [ ! -e /dev/nvme2n1 ]; do
    echo "Waiting for EBS volumes..."
    sleep 5
done

# Format volumes if needed
echo "Setting up EBS volumes..."
if ! blkid /dev/nvme1n1; then 
    mkfs.xfs /dev/nvme1n1
fi
if ! blkid /dev/nvme2n1; then 
    mkfs.xfs /dev/nvme2n1
fi

# Mount volumes
mkdir -p /var/opt/redislabs
mount /dev/nvme1n1 /var/opt/redislabs
mkdir -p /var/opt/redislabs/persist
mount /dev/nvme2n1 /var/opt/redislabs/persist

# Add to fstab
echo "/dev/nvme1n1 /var/opt/redislabs xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/nvme2n1 /var/opt/redislabs/persist xfs defaults,nofail 0 2" >> /etc/fstab

# Create redislabs user and group (Redis Enterprise installer will use these)
# This must be done before setting ownership
if ! getent group redislabs > /dev/null 2>&1; then
    groupadd redislabs
fi
if ! getent passwd redislabs > /dev/null 2>&1; then
    useradd -g redislabs -d /var/opt/redislabs -s /bin/bash redislabs
fi

# Set proper ownership per Redis documentation
# Critical: Must be redislabs:redislabs for Redis Enterprise to function correctly
# Reference: https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/configuring-aws-instances/#storage
chown -R redislabs:redislabs /var/opt/redislabs
chmod 755 /var/opt/redislabs /var/opt/redislabs/persist

# Create marker for completion
touch /tmp/basic-setup-complete

echo "Basic setup completed - $(date)"