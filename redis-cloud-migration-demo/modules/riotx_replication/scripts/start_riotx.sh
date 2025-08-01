#!/bin/bash

# =============================================================================
# RIOT-X Live Replication Script
# Replicates data from ElastiCache to Redis Cloud in real-time
# =============================================================================

set -e

# Configuration variables (injected by Terraform)
ELASTICACHE_ENDPOINT="${elasticache_endpoint}"
REDISCLOUD_ENDPOINT="${rediscloud_private_endpoint}"
REDISCLOUD_PASSWORD="${rediscloud_password}"
REPLICATION_MODE="${replication_mode}"
ENABLE_METRICS="${enable_metrics}"
METRICS_PORT="${metrics_port}"
LOG_KEYS="${log_keys}"

# Logging setup
LOG_FILE="/home/ubuntu/riotx.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== RIOT-X Live Replication Started ==="
echo "Timestamp: $(date)"
echo "Source:      redis://$ELASTICACHE_ENDPOINT:6379"
echo "Target:      redis://:***@$REDISCLOUD_ENDPOINT"
echo "Mode:        $REPLICATION_MODE"
echo "Metrics:     $ENABLE_METRICS (port: $METRICS_PORT)"
echo "Log Keys:    $LOG_KEYS"
echo "=========================================="

# Build RIOT-X command dynamically
RIOTX_CMD="riotx replicate"
RIOTX_CMD="$RIOTX_CMD redis://$ELASTICACHE_ENDPOINT:6379"
RIOTX_CMD="$RIOTX_CMD redis://:$REDISCLOUD_PASSWORD@$REDISCLOUD_ENDPOINT"
RIOTX_CMD="$RIOTX_CMD --mode $REPLICATION_MODE"
RIOTX_CMD="$RIOTX_CMD --progress log"

# Add optional features
if [ "$LOG_KEYS" = "true" ]; then
    RIOTX_CMD="$RIOTX_CMD --log-keys"
fi

if [ "$ENABLE_METRICS" = "true" ]; then
    RIOTX_CMD="$RIOTX_CMD --metrics"
    RIOTX_CMD="$RIOTX_CMD --metrics-jvm"
    RIOTX_CMD="$RIOTX_CMD --metrics-redis"
    RIOTX_CMD="$RIOTX_CMD --metrics-name=riotx"
    RIOTX_CMD="$RIOTX_CMD --metrics-port=$METRICS_PORT"
fi

echo "Executing: $RIOTX_CMD"
echo "=========================================="

# Execute RIOT-X replication
eval "$RIOTX_CMD"

echo "=== RIOT-X replication completed ==="