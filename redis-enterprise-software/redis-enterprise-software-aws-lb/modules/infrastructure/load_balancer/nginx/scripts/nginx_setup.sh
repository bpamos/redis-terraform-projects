#!/bin/bash

# =============================================================================
# NGINX Load Balancer Setup Script for Redis Enterprise
# =============================================================================
# Installs NGINX with stream module using package manager (fast and reliable)
# Supports both Ubuntu and RHEL/CentOS platforms
# =============================================================================

set -euo pipefail

# Configuration variables
NGINX_USER="www-data"
LOG_FILE="/tmp/nginx_setup.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Detect platform
detect_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        error_exit "Cannot detect operating system"
    fi
    
    log "Detected OS: $OS $OS_VERSION"
}

# Install NGINX with stream module
install_nginx() {
    log "Installing NGINX with stream module for $OS"
    
    case "$OS" in
        ubuntu|debian)
            # Update package list
            apt-get update
            
            # Install NGINX and stream module
            apt-get install -y \
                nginx \
                libnginx-mod-stream
            
            log "NGINX installed with stream module"
            ;;
            
        rhel|centos|rocky|almalinux)
            # Enable EPEL repository for NGINX
            yum install -y epel-release
            
            # Install NGINX and stream module
            yum install -y \
                nginx \
                nginx-mod-stream
            
            # Set NGINX_USER for RHEL-based systems
            NGINX_USER="nginx"
            log "NGINX installed with stream module"
            ;;
            
        *)
            error_exit "Unsupported operating system: $OS"
            ;;
    esac
}

# Configure NGINX directories and permissions
configure_nginx() {
    log "Configuring NGINX directories and permissions"
    
    # Ensure necessary directories exist
    mkdir -p /var/cache/nginx
    mkdir -p /var/log/nginx
    mkdir -p /etc/nginx/conf.d
    
    # Set proper ownership for Ubuntu vs RHEL
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        NGINX_USER="www-data"
        chown -R www-data:www-data /var/cache/nginx /var/log/nginx
    else
        NGINX_USER="nginx"
        chown -R nginx:nginx /var/cache/nginx /var/log/nginx
    fi
    
    log "NGINX directories configured with user: $NGINX_USER"
}

# Configure systemd service
configure_systemd_service() {
    log "Configuring NGINX systemd service"
    
    # Enable and start NGINX service
    systemctl daemon-reload
    systemctl enable nginx
    
    log "NGINX service enabled and ready to start"
}

# Set up logrotate
setup_logrotate() {
    log "Setting up log rotation"
    
    cat > /etc/logrotate.d/nginx << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
EOF
}

# Create basic nginx configuration directory structure
setup_config_structure() {
    log "Setting up configuration structure"
    
    # Backup original config if it exists
    if [ -f /etc/nginx/nginx.conf ]; then
        mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    fi
    
    # Create basic directory structure
    mkdir -p /etc/nginx/{conf.d,sites-available,sites-enabled}
    
    log "NGINX configuration will be managed by Terraform"
}

# Verify installation
verify_installation() {
    log "Verifying NGINX installation"
    
    # Check if nginx binary exists and is executable
    if [ ! -x /usr/sbin/nginx ]; then
        error_exit "NGINX binary not found or not executable"
    fi
    
    # Check for stream module availability
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        if [ ! -f /usr/lib/nginx/modules/ngx_stream_module.so ]; then
            error_exit "Stream module not found - libnginx-mod-stream not installed"
        fi
        log "Stream module found: /usr/lib/nginx/modules/ngx_stream_module.so"
    else
        # RHEL-based systems
        if [ ! -f /usr/lib64/nginx/modules/ngx_stream_module.so ]; then
            error_exit "Stream module not found - nginx-mod-stream not installed"
        fi
        log "Stream module found: /usr/lib64/nginx/modules/ngx_stream_module.so"
    fi
    
    # Get version info
    local version_info
    version_info=$(/usr/sbin/nginx -V 2>&1)
    log "NGINX installed successfully:"
    log "$version_info"
}

# Main execution
main() {
    log "Starting NGINX installation for Redis Enterprise load balancing"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root"
    fi
    
    detect_platform
    install_nginx
    configure_nginx
    configure_systemd_service
    setup_logrotate
    setup_config_structure
    verify_installation
    
    log "NGINX installation completed successfully"
    log "NGINX is ready to be configured for Redis Enterprise load balancing"
    log "Note: NGINX service is enabled but not started. It will be started after configuration."
}

# Execute main function
main "$@"