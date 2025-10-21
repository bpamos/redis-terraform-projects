#!/bin/bash

# Minimal RedisArena EC2 Setup - Maximum Speed for Demos
# Skips ALL package operations - uses only pre-installed packages

exec > /var/log/user-data.log 2>&1
set -e

echo "=== MINIMAL RedisArena EC2 Setup Started ==="
echo "Timestamp: $(date)"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "⚡ ULTRA-FAST setup - only installing essential packages"

# MINIMAL USER-DATA - Only basic setup, packages installed via Terraform provisioner
echo "⚡ MINIMAL user-data setup - packages will be installed via Terraform provisioner"

# Fix repository mirror for when provisioner runs apt
echo "🔧 Fixing Ubuntu repository mirror for faster package installation..."
sudo sed -i 's/us-west-2.ec2.archive.ubuntu.com/archive.ubuntu.com/g' /etc/apt/sources.list

# Wait for system to be fully ready
echo "⏳ Waiting for system to be fully ready..."
sleep 30

echo "✅ Minimal user-data setup completed - ready for provisioner"

# Create application directories
echo "📁 Setting up application directories..."
sudo mkdir -p /opt/redisarena
sudo mkdir -p /var/log/redisarena
sudo chown ubuntu:ubuntu /opt/redisarena
sudo chown ubuntu:ubuntu /var/log/redisarena

# Skip nginx entirely - RedisArena can run on port 5000 directly
echo "⏭️ Skipping nginx setup - will run on port 5000 directly"

# Create a simple HTML file for port 80 if needed
echo "🌐 Creating simple port 80 redirect..."
sudo mkdir -p /var/www/html
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>RedisArena Demo</title>
    <meta http-equiv="refresh" content="0; url=http://$(curl -s ifconfig.me):5000">
</head>
<body>
    <h1>Redirecting to RedisArena...</h1>
    <p>If not redirected, go to: <a href="http://$(curl -s ifconfig.me):5000">http://$(curl -s ifconfig.me):5000</a></p>
</body>
</html>
EOF

# Install completion marker immediately
echo "✅ MINIMAL setup completed in seconds!" > /tmp/ec2-setup-complete

# Log completion
echo "=== MINIMAL RedisArena EC2 Setup Completed ==="
echo "Timestamp: $(date)"
echo "Total time: Under 30 seconds!"
echo "🚀 RedisArena EC2 instance ready for application installation!"
echo ""
echo "NOTE: This minimal setup:"
echo "- Skips ALL package installations for maximum speed"
echo "- RedisArena will handle its own dependencies during app installation"
echo "- Runs on port 5000 directly (no nginx proxy)"
echo "- Perfect for demos where speed matters most"