#!/bin/bash
# =============================================================================
# REDIS ENTERPRISE CLUSTER MANAGEMENT SCRIPT
# =============================================================================
# Comprehensive script for managing Redis Enterprise clusters
# Usage: ./cluster_management.sh <command> [options]
# =============================================================================

set -e

SCRIPT_NAME=$(basename "$0")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Redis Enterprise Cluster Management Script

Usage: $SCRIPT_NAME <command> [options]

Commands:
  status                          - Show comprehensive cluster status
  init <username> <password>      - Initialize new cluster (primary node only)
  join <primary_ip> <username> <password> - Join existing cluster
  create-db <db_name> [options]   - Create a new database
  list-dbs                        - List all databases
  backup-db <db_name>             - Backup a database
  restore-db <db_name> <backup>   - Restore database from backup
  show-logs [service]             - Show Redis Enterprise logs
  health-check                    - Perform comprehensive health check
  cluster-info                    - Show detailed cluster information
  node-info                       - Show detailed node information
  reset-password <username>       - Reset cluster admin password

Database Creation Options:
  --memory <size>                 - Memory limit (e.g., 1gb, 512mb)
  --port <port>                   - Database port (default: auto)
  --replication                   - Enable replication
  --persistence                   - Enable persistence
  --sharding                      - Enable sharding

Examples:
  $SCRIPT_NAME status
  $SCRIPT_NAME init admin@redis.com MyPassword123
  $SCRIPT_NAME join 10.0.1.10 admin@redis.com MyPassword123
  $SCRIPT_NAME create-db myapp --memory 512mb --port 12000 --replication
  $SCRIPT_NAME health-check
  $SCRIPT_NAME show-logs
EOF
}

# Function to check if Redis Enterprise is installed and running
check_redis_enterprise() {
    if ! command -v /opt/redislabs/bin/rladmin &> /dev/null; then
        print_error "Redis Enterprise is not installed on this system"
        exit 1
    fi
    
    if ! systemctl is-active --quiet rlec_supervisor; then
        print_warning "Redis Enterprise supervisor service is not running"
        print_status "Attempting to start Redis Enterprise services..."
        sudo systemctl start rlec_supervisor || {
            print_error "Failed to start Redis Enterprise services"
            exit 1
        }
    fi
}

# Function to show comprehensive status
show_status() {
    print_header "Redis Enterprise Cluster Status"
    
    print_status "Service Status:"
    sudo systemctl status rlec_supervisor --no-pager --lines=5 || true
    echo ""
    
    print_status "Cluster Status:"
    sudo /opt/redislabs/bin/rladmin status || echo "Cluster not configured"
    echo ""
    
    print_status "Node Information:"
    sudo /opt/redislabs/bin/rladmin info node || echo "Node not configured"
    echo ""
    
    print_status "Cluster Information:"
    sudo /opt/redislabs/bin/rladmin info cluster || echo "Cluster not configured"
    echo ""
    
    print_status "Database Status:"
    sudo /opt/redislabs/bin/rladmin status databases || echo "No databases configured"
    echo ""
    
    print_status "Storage Usage:"
    df -h /var/opt/redislabs* 2>/dev/null || echo "Storage not mounted"
    echo ""
    
    print_status "Memory Usage:"
    free -h
    echo ""
    
    print_status "System Load:"
    uptime
}

# Function to initialize cluster
init_cluster() {
    if [ $# -lt 2 ]; then
        print_error "Usage: $SCRIPT_NAME init <username> <password> [cluster_name]"
        exit 1
    fi
    
    local username="$1"
    local password="$2"
    local cluster_name="${3:-redis-cluster.local}"
    
    print_header "Initializing Redis Enterprise Cluster"
    
    # Wait for Redis Enterprise services to be ready
    print_status "Waiting for Redis Enterprise services to be ready..."
    for i in {1..60}; do
        if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then
            print_status "Redis Enterprise services are ready"
            break
        fi
        echo "Waiting for services... ($i/60)"
        sleep 5
    done
    
    # Initialize cluster using rladmin
    print_status "Creating Redis Enterprise cluster using rladmin..."
    local cmd="sudo /opt/redislabs/bin/rladmin cluster create"
    cmd="$cmd name $cluster_name"
    cmd="$cmd username $username"
    cmd="$cmd password $password"
    cmd="$cmd ephemeral_path /var/opt/redislabs"
    cmd="$cmd persistent_path /var/opt/redislabs/persist"
    cmd="$cmd rack_aware"
    
    print_status "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        print_status "Cluster initialized successfully!"
        touch /tmp/cluster-initialized
        
        # Check cluster status
        print_status "Verifying cluster status..."
        sudo /opt/redislabs/bin/rladmin status
    else
        print_error "Failed to initialize cluster"
        exit 1
    fi
}

# Function to join cluster
join_cluster() {
    if [ $# -ne 3 ]; then
        print_error "Usage: $SCRIPT_NAME join <primary_ip> <username> <password>"
        exit 1
    fi
    
    local primary_ip="$1"
    local username="$2"
    local password="$3"
    
    print_header "Joining Redis Enterprise Cluster"
    
    # Wait for local services to be ready
    print_status "Waiting for local Redis Enterprise services to be ready..."
    for i in {1..60}; do
        if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then
            print_status "Local services are ready"
            break
        fi
        echo "Waiting for local services... ($i/60)"
        sleep 5
    done
    
    # Wait for primary node to be accessible
    print_status "Waiting for primary node to be accessible..."
    for i in {1..30}; do
        if nc -z "$primary_ip" 8443 >/dev/null 2>&1; then
            print_status "Primary node is accessible"
            break
        fi
        echo "Waiting for primary node... ($i/30)"
        sleep 5
    done
    
    # Join cluster using rladmin
    print_status "Joining cluster using rladmin..."
    local cmd="sudo /opt/redislabs/bin/rladmin cluster join"
    cmd="$cmd nodes $primary_ip"
    cmd="$cmd username $username"
    cmd="$cmd password $password"
    cmd="$cmd ephemeral_path /var/opt/redislabs"
    cmd="$cmd persistent_path /var/opt/redislabs/persist"
    
    print_status "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        print_status "Successfully joined cluster!"
        touch /tmp/cluster-joined
        
        # Verify cluster status
        print_status "Verifying cluster status..."
        sleep 10
        sudo /opt/redislabs/bin/rladmin status
    else
        print_error "Failed to join cluster"
        exit 1
    fi
}

# Function to create database
create_database() {
    if [ $# -lt 1 ]; then
        print_error "Usage: $SCRIPT_NAME create-db <db_name> [options]"
        exit 1
    fi
    
    local db_name="$1"
    shift
    
    # Default values
    local memory="512mb"
    local port=""
    local replication=false
    local persistence=false
    local sharding=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --memory)
                memory="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --replication)
                replication=true
                shift
                ;;
            --persistence)
                persistence=true
                shift
                ;;
            --sharding)
                sharding=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    print_header "Creating Database: $db_name"
    print_status "Memory: $memory"
    print_status "Replication: $replication"
    print_status "Persistence: $persistence"
    print_status "Sharding: $sharding"
    
    # Build rladmin command
    local cmd="sudo /opt/redislabs/bin/rladmin create db $db_name memory_size $memory"
    
    if [ -n "$port" ]; then
        cmd="$cmd port $port"
    fi
    
    if [ "$replication" = true ]; then
        cmd="$cmd replication true"
    fi
    
    if [ "$persistence" = true ]; then
        cmd="$cmd persistence aof"
    fi
    
    if [ "$sharding" = true ]; then
        cmd="$cmd sharding true"
    fi
    
    print_status "Executing: $cmd"
    eval "$cmd"
    
    print_status "Database '$db_name' created successfully!"
}

# Function to list databases
list_databases() {
    print_header "Redis Enterprise Databases"
    sudo /opt/redislabs/bin/rladmin status databases
}

# Function to show logs
show_logs() {
    local service="${1:-all}"
    
    print_header "Redis Enterprise Logs"
    
    case $service in
        "all")
            print_status "Recent Redis Enterprise logs:"
            sudo tail -n 50 /var/opt/redislabs/log/*.log 2>/dev/null || print_warning "No logs found"
            ;;
        "supervisor")
            sudo journalctl -u rlec_supervisor --no-pager -n 50
            ;;
        "cluster")
            sudo tail -n 50 /var/opt/redislabs/log/cluster.log 2>/dev/null || print_warning "Cluster log not found"
            ;;
        *)
            print_error "Unknown service: $service"
            print_status "Available services: all, supervisor, cluster"
            exit 1
            ;;
    esac
}

# Function to perform health check
health_check() {
    print_header "Redis Enterprise Health Check"
    
    local issues=0
    
    # Check Redis Enterprise service
    print_status "Checking Redis Enterprise service..."
    if systemctl is-active --quiet rlec_supervisor; then
        print_status "✓ Redis Enterprise service is running"
    else
        print_error "✗ Redis Enterprise service is not running"
        ((issues++))
    fi
    
    # Check disk space
    print_status "Checking disk space..."
    local redis_usage=$(df /var/opt/redislabs | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$redis_usage" -lt 80 ]; then
        print_status "✓ Disk space is adequate ($redis_usage% used)"
    else
        print_warning "⚠ Disk space is high ($redis_usage% used)"
        ((issues++))
    fi
    
    # Check memory
    print_status "Checking memory usage..."
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -lt 90 ]; then
        print_status "✓ Memory usage is normal ($mem_usage% used)"
    else
        print_warning "⚠ Memory usage is high ($mem_usage% used)"
        ((issues++))
    fi
    
    # Check cluster status
    print_status "Checking cluster status..."
    if sudo /opt/redislabs/bin/rladmin status | grep -q "OK"; then
        print_status "✓ Cluster status is OK"
    else
        print_warning "⚠ Cluster status may have issues"
        ((issues++))
    fi
    
    # Summary
    echo ""
    if [ $issues -eq 0 ]; then
        print_status "✓ Health check passed - no issues detected"
    else
        print_warning "⚠ Health check found $issues potential issues"
    fi
}

# Function to show cluster info
cluster_info() {
    print_header "Detailed Cluster Information"
    sudo /opt/redislabs/bin/rladmin info cluster
}

# Function to show node info
node_info() {
    print_header "Detailed Node Information"
    sudo /opt/redislabs/bin/rladmin info node
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Check Redis Enterprise before running commands (except for help)
if [ "$1" != "help" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    check_redis_enterprise
fi

case "$1" in
    "status")
        show_status
        ;;
    "init")
        shift
        init_cluster "$@"
        ;;
    "join")
        shift
        join_cluster "$@"
        ;;
    "create-db")
        shift
        create_database "$@"
        ;;
    "list-dbs")
        list_databases
        ;;
    "show-logs")
        shift
        show_logs "$@"
        ;;
    "health-check")
        health_check
        ;;
    "cluster-info")
        cluster_info
        ;;
    "node-info")
        node_info
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac