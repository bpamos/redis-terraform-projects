#!/bin/bash
#===============================================================================
# Redis Enterprise Active-Active (CRDB) Database Creation Script
#===============================================================================
# This script creates a CRDB database across multiple Redis Enterprise clusters
#
# Usage:
#   - Called by Terraform: terraform apply (env vars set automatically)
#   - Manual execution: ./create-crdb.sh (reads from terraform output)
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1" >&2
}

#===============================================================================
# CONFIGURATION
#===============================================================================

# If running manually (not from Terraform), load config from terraform output
if [ -z "${CRDB_CONFIG_JSON:-}" ]; then
    log_info "Running in standalone mode - reading Terraform outputs..."

    # Check if we're in the right directory
    if [ ! -f "main.tf" ]; then
        log_error "Not in Terraform root directory. Please run from redis-enterprise-software-aws-aa/"
        exit 1
    fi

    # Read Terraform outputs
    CLUSTERS=$(terraform output -json clusters 2>/dev/null || echo "{}")

    if [ "$CLUSTERS" = "{}" ]; then
        log_error "No clusters found in Terraform outputs. Run 'terraform apply' first."
        exit 1
    fi

    # Extract configuration
    REGION1=$(echo "$CLUSTERS" | jq -r 'keys[0]')
    REGION2=$(echo "$CLUSTERS" | jq -r 'keys[1]')

    CLUSTER1_FQDN=$(echo "$CLUSTERS" | jq -r ".\"$REGION1\".cluster_fqdn")
    CLUSTER1_IP=$(echo "$CLUSTERS" | jq -r ".\"$REGION1\".private_ips[0]")

    CLUSTER2_FQDN=$(echo "$CLUSTERS" | jq -r ".\"$REGION2\".cluster_fqdn")
    CLUSTER2_IP=$(echo "$CLUSTERS" | jq -r ".\"$REGION2\".private_ips[0]")

    CLUSTER_USERNAME="${REDIS_USERNAME:-admin@admin.com}"
    CLUSTER_PASSWORD="${REDIS_PASSWORD:-admin}"
    CRDB_NAME="${CRDB_NAME:-active-active-db}"
    CRDB_PORT="${CRDB_PORT:-12000}"
    CRDB_MEMORY="${CRDB_MEMORY:-1073741824}"

    log_info "Configuration loaded from Terraform outputs"
fi

# Validate required variables
if [ -z "${CLUSTER_USERNAME:-}" ] || [ -z "${CLUSTER_PASSWORD:-}" ]; then
    log_error "Missing required variables: CLUSTER_USERNAME, CLUSTER_PASSWORD"
    exit 1
fi

log_info "CRDB Name: ${CRDB_NAME:-active-active-db}"
log_info "CRDB Port: ${CRDB_PORT:-12000}"

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

# Retry a command with exponential backoff
retry_with_backoff() {
    local max_attempts=5
    local attempt=1
    local delay=5
    local max_delay=60

    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi

        if [ $attempt -eq $max_attempts ]; then
            log_error "Command failed after $max_attempts attempts"
            return 1
        fi

        log_warning "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
        sleep $delay

        # Exponential backoff with cap
        delay=$((delay * 2))
        if [ $delay -gt $max_delay ]; then
            delay=$max_delay
        fi

        ((attempt++))
    done
}

# Wait for cluster to be ready and responsive
wait_for_cluster() {
    local cluster_url=$1
    local cluster_name=$2
    local max_attempts=30
    local attempt=1

    log_info "Waiting for cluster '$cluster_name' to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if curl -k -s -f --max-time 10 \
            -u "${CLUSTER_USERNAME}:${CLUSTER_PASSWORD}" \
            "${cluster_url}/v1/cluster" > /dev/null 2>&1; then
            log_success "Cluster '$cluster_name' is ready"
            return 0
        fi

        echo -n "."
        sleep 10
        ((attempt++))
    done

    echo ""
    log_error "Cluster '$cluster_name' did not become ready within $((max_attempts * 10)) seconds"
    return 1
}

# Check if CRDB already exists on a cluster
check_crdb_exists() {
    local cluster_url=$1
    local crdb_name=$2

    local response=$(curl -k -s --max-time 10 \
        -u "${CLUSTER_USERNAME}:${CLUSTER_PASSWORD}" \
        "${cluster_url}/v1/crdbs" 2>/dev/null || echo "[]")

    if echo "$response" | jq -e ".[] | select(.name==\"${crdb_name}\")" > /dev/null 2>&1; then
        return 0  # CRDB exists
    else
        return 1  # CRDB doesn't exist
    fi
}

# Create CRDB via REST API
create_crdb_api() {
    local primary_url=$1
    local config_file=$2

    local response=$(curl -k -s -w "\n%{http_code}" --max-time 60 \
        -u "${CLUSTER_USERNAME}:${CLUSTER_PASSWORD}" \
        -X POST "${primary_url}/v1/crdbs" \
        -H "Content-Type: application/json" \
        -d @"${config_file}")

    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        log_success "CRDB created successfully (HTTP $http_code)"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 0
    else
        log_error "CRDB creation failed (HTTP $http_code)"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        return 1
    fi
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================

log_info "========================================================================"
log_info "Redis Enterprise Active-Active (CRDB) Database Creation"
log_info "========================================================================"

# If called from Terraform, CRDB_CONFIG_JSON is already set
if [ -n "${CRDB_CONFIG_JSON:-}" ]; then
    # Parse config from Terraform
    CRDB_NAME=$(echo "$CRDB_CONFIG_JSON" | jq -r '.name')
    PRIMARY_CLUSTER_URL=$(echo "$CRDB_CONFIG_JSON" | jq -r '.instances[0].cluster.url')
    PRIMARY_CLUSTER_FQDN=$(echo "$CRDB_CONFIG_JSON" | jq -r '.instances[0].cluster.name')

    # Create temporary config file
    CONFIG_FILE=$(mktemp /tmp/crdb_config.XXXXXX.json)
    echo "$CRDB_CONFIG_JSON" > "$CONFIG_FILE"
    trap "rm -f $CONFIG_FILE" EXIT

    log_info "Configuration received from Terraform"
else
    # Build config from variables (standalone mode)
    PRIMARY_CLUSTER_URL="https://${CLUSTER1_IP}:9443"
    PRIMARY_CLUSTER_FQDN="$CLUSTER1_FQDN"

    CONFIG_FILE=$(mktemp /tmp/crdb_config.XXXXXX.json)
    trap "rm -f $CONFIG_FILE" EXIT

    cat > "$CONFIG_FILE" <<EOF
{
  "name": "$CRDB_NAME",
  "instances": [
    {
      "cluster": {
        "name": "$CLUSTER1_FQDN",
        "url": "https://${CLUSTER1_IP}:9443",
        "credentials": {
          "username": "$CLUSTER_USERNAME",
          "password": "$CLUSTER_PASSWORD"
        }
      },
      "compression": 6
    },
    {
      "cluster": {
        "name": "$CLUSTER2_FQDN",
        "url": "https://${CLUSTER2_IP}:9443",
        "credentials": {
          "username": "$CLUSTER_USERNAME",
          "password": "$CLUSTER_PASSWORD"
        }
      },
      "compression": 6
    }
  ],
  "default_db_config": {
    "name": "$CRDB_NAME",
    "memory_size": $CRDB_MEMORY,
    "port": $CRDB_PORT,
    "bigstore": false,
    "replication": true,
    "aof_policy": "appendfsync-every-sec",
    "snapshot_policy": [],
    "sharding": false,
    "shards_count": 1
  }
}
EOF
fi

log_info "Primary cluster: $PRIMARY_CLUSTER_FQDN"
log_info "CRDB configuration:"
cat "$CONFIG_FILE" | jq '.'

# Step 1: Wait for all clusters to be ready
echo ""
log_info "Step 1/3: Waiting for clusters to be ready..."
for cluster_url in $(echo "$CRDB_CONFIG_JSON" | jq -r '.instances[].cluster.url' 2>/dev/null || jq -r '.instances[].cluster.url' < "$CONFIG_FILE"); do
    cluster_name=$(echo "$CRDB_CONFIG_JSON" | jq -r ".instances[] | select(.cluster.url==\"$cluster_url\") | .cluster.name" 2>/dev/null || jq -r ".instances[] | select(.cluster.url==\"$cluster_url\") | .cluster.name" < "$CONFIG_FILE")
    wait_for_cluster "$cluster_url" "$cluster_name" || exit 1
done

# Step 2: Check if CRDB already exists (idempotency)
echo ""
log_info "Step 2/3: Checking if CRDB '$CRDB_NAME' already exists..."
if check_crdb_exists "$PRIMARY_CLUSTER_URL" "$CRDB_NAME"; then
    log_warning "CRDB '$CRDB_NAME' already exists on cluster - skipping creation"
    echo ""
    log_info "To view CRDB details, run:"
    log_info "  curl -k -u '${CLUSTER_USERNAME}:PASSWORD' ${PRIMARY_CLUSTER_URL}/v1/crdbs | jq '.[] | select(.name==\"${CRDB_NAME}\")'"
    exit 0
fi

log_info "CRDB does not exist - proceeding with creation"

# Step 3: Create CRDB with retry
echo ""
log_info "Step 3/3: Creating CRDB database '$CRDB_NAME'..."
if retry_with_backoff create_crdb_api "$PRIMARY_CLUSTER_URL" "$CONFIG_FILE"; then
    echo ""
    log_success "========================================================================"
    log_success "CRDB '$CRDB_NAME' created successfully!"
    log_success "========================================================================"
    echo ""
    log_info "CRDB endpoints:"

    # Extract and display endpoints
    for cluster_url in $(jq -r '.instances[].cluster.url' < "$CONFIG_FILE"); do
        cluster_name=$(jq -r ".instances[] | select(.cluster.url==\"$cluster_url\") | .cluster.name" < "$CONFIG_FILE")
        endpoint="redis-${CRDB_PORT}.${cluster_name}"
        log_info "  • $endpoint:$CRDB_PORT"
    done

    echo ""
    log_info "Test replication with:"
    log_info "  redis-cli -h <endpoint> -p $CRDB_PORT SET testkey 'hello'"
    log_info "  redis-cli -h <other-endpoint> -p $CRDB_PORT GET testkey"
else
    echo ""
    log_error "========================================================================"
    log_error "Failed to create CRDB after multiple attempts"
    log_error "========================================================================"
    exit 1
fi
