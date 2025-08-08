#!/bin/bash
# =============================================================================
# REDIS ENTERPRISE CLUSTER JOIN SCRIPT
# =============================================================================
# Script to join Redis Enterprise nodes to an existing cluster
# Usage: ./join_cluster.sh <primary_node_ip> <cluster_username> <cluster_password>
# =============================================================================

set -e

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <primary_node_ip> <cluster_username> <cluster_password>"
    echo "Example: $0 10.0.1.10 admin@redis.com MyPassword123"
    exit 1
fi

PRIMARY_NODE_IP="$1"
CLUSTER_USERNAME="$2"
CLUSTER_PASSWORD="$3"

echo "=== Redis Enterprise Cluster Join ==="
echo "Primary Node IP: $PRIMARY_NODE_IP"
echo "Username: $CLUSTER_USERNAME"
echo "Timestamp: $(date)"

# Wait for local Redis Enterprise API to be available
echo "Waiting for local Redis Enterprise API to be ready..."
for i in {1..60}; do
    if curl -k -s --connect-timeout 5 https://localhost:9443/v1/bootstrap/create_cluster >/dev/null 2>&1; then
        echo "Local Redis Enterprise API is ready"
        break
    fi
    echo "Waiting for local API... ($i/60)"
    sleep 10
done

# Check if primary cluster is ready
echo "Checking if primary cluster is accessible..."
for i in {1..60}; do
    if curl -k -s --connect-timeout 5 "https://${PRIMARY_NODE_IP}:9443/v1/cluster" >/dev/null 2>&1; then
        echo "Primary cluster is accessible"
        break
    fi
    echo "Waiting for primary cluster... ($i/60)"
    sleep 10
done

# Join the cluster using rladmin
echo "Joining Redis Enterprise cluster using rladmin..."
JOIN_CMD="sudo /opt/redislabs/bin/rladmin cluster join"
JOIN_CMD="$JOIN_CMD nodes $PRIMARY_NODE_IP"
JOIN_CMD="$JOIN_CMD username $CLUSTER_USERNAME"
JOIN_CMD="$JOIN_CMD password $CLUSTER_PASSWORD"
JOIN_CMD="$JOIN_CMD ephemeral_path /var/opt/redislabs"
JOIN_CMD="$JOIN_CMD persistent_path /var/opt/redislabs/persist"

echo "Executing: $JOIN_CMD"
eval "$JOIN_CMD"

if [ $? -eq 0 ]; then
    echo "Successfully joined Redis Enterprise cluster!"
    
    # Mark as joined
    touch /tmp/cluster-joined
    
    # Wait for node to be fully integrated
    echo "Waiting for node integration to complete..."
    sleep 30
    
    # Check cluster status
    echo "Checking cluster status..."
    sudo /opt/redislabs/bin/rladmin status || true
    
    echo "Node successfully joined the Redis Enterprise cluster!"
    
else
    echo "ERROR: Failed to join Redis Enterprise cluster"
    exit 1
fi

echo "=== Cluster Join Completed ==="
echo "Use 'sudo /opt/redislabs/bin/rladmin status' to verify cluster status"
echo "Timestamp: $(date)"