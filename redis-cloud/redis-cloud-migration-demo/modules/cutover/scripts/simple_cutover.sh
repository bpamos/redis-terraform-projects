#!/bin/bash

# Simple Redis Migration Cutover Script - Demo Version
# Minimal script that avoids permission issues

# Set PATH explicitly
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Configuration from environment variables or defaults
REDIS_CLOUD_HOST="${REDIS_CLOUD_ENDPOINT:-redis-example.cloud.rlrcp.com}"
REDIS_CLOUD_PORT="${REDIS_CLOUD_PORT:-18619}"
REDIS_CLOUD_PASSWORD="${REDIS_CLOUD_PASSWORD:-your-redis-cloud-password}"

APP_DIR="/opt/redisarena"
ENV_FILE="$APP_DIR/.env"
BACKUP_FILE="$APP_DIR/.env.backup"

# Simple logging function (no file logging to avoid permissions)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to validate Redis Cloud connectivity
validate_redis_cloud() {
    log "🔍 Validating Redis Cloud connectivity..."
    log "📋 Target: $REDIS_CLOUD_HOST:$REDIS_CLOUD_PORT"
    
    # Test Redis Cloud connection
    if [ -x "/usr/bin/redis-cli" ] || command -v redis-cli >/dev/null 2>&1; then
        log "🔧 Testing connection with redis-cli..."
        local ping_result
        ping_result=$(/usr/bin/redis-cli -h "$REDIS_CLOUD_HOST" -p "$REDIS_CLOUD_PORT" -a "$REDIS_CLOUD_PASSWORD" ping 2>&1)
        if echo "$ping_result" | /usr/bin/grep -q "PONG"; then
            log "✅ Redis Cloud connectivity verified"
            log "🔗 Successfully connected to Redis Cloud"
            log "📡 PING → PONG response received"
            
            # Show database size and sample keys to prove data exists
            log "🔍 Scanning Redis Cloud database for data..."
            local db_size
            db_size=$(/usr/bin/redis-cli -h "$REDIS_CLOUD_HOST" -p "$REDIS_CLOUD_PORT" -a "$REDIS_CLOUD_PASSWORD" dbsize 2>/dev/null || echo "unknown")
            log "📊 Redis Cloud database contains $db_size keys"
            
            if [ "$db_size" != "unknown" ] && [ "$db_size" -gt 0 ]; then
                log "🔬 Sample keys from Redis Cloud:"
                # Get a few sample keys to prove data exists
                local sample_keys
                sample_keys=$(/usr/bin/redis-cli -h "$REDIS_CLOUD_HOST" -p "$REDIS_CLOUD_PORT" -a "$REDIS_CLOUD_PASSWORD" --scan --count 5 2>/dev/null | head -5)
                if [ -n "$sample_keys" ]; then
                    echo "$sample_keys" | while IFS= read -r key; do
                        if [ -n "$key" ]; then
                            local key_type
                            key_type=$(/usr/bin/redis-cli -h "$REDIS_CLOUD_HOST" -p "$REDIS_CLOUD_PORT" -a "$REDIS_CLOUD_PASSWORD" type "$key" 2>/dev/null || echo "unknown")
                            log "   📄 $key (type: $key_type)"
                        fi
                    done
                else
                    log "   📄 Keys exist but unable to scan (may require AUTH)"
                fi
            else
                log "   📄 Database appears to be empty or inaccessible"
            fi
            
            return 0
        else
            log "❌ Redis Cloud connection failed"
            log "🔍 Checking connection details..."
            log "   Host: $REDIS_CLOUD_HOST"
            log "   Port: $REDIS_CLOUD_PORT"
            log "   Password: ${REDIS_CLOUD_PASSWORD:0:8}... (truncated)"
            
            # Try to get more specific error
            local error_output
            error_output=$(/usr/bin/redis-cli -h "$REDIS_CLOUD_HOST" -p "$REDIS_CLOUD_PORT" -a "$REDIS_CLOUD_PASSWORD" ping 2>&1)
            log "   Error: $error_output"
            return 1
        fi
    else
        log "❌ redis-cli not found"
        log "🔍 redis-cli is required for Redis Cloud connectivity testing"
        return 1
    fi
}

# Function to backup current configuration
backup_config() {
    log "💾 Backing up current configuration..."
    if [ -f "$ENV_FILE" ]; then
        # Always create a backup with the original ElastiCache configuration for rollback
        # This ensures rollback always goes back to ElastiCache, not Redis Cloud
        cat > "$BACKUP_FILE" << 'EOF'
# RedisArena Configuration
REDIS_HOST=${ELASTICACHE_HOST:-elasticache-example.cache.amazonaws.com}
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Application Settings
FLASK_ENV=production
SECRET_KEY=your-secret-key-change-in-production

# Performance Settings
REDIS_POOL_MAX_CONNECTIONS=20
HEALTH_CHECK_INTERVAL=30
EOF
        log "✅ ElastiCache configuration backed up to $BACKUP_FILE for rollback"
    else
        log "⚠️ No existing configuration found"
    fi
}

# Function to update Redis configuration
update_redis_config() {
    log "⚙️ Updating Redis configuration for cutover..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log "❌ Configuration file not found: $ENV_FILE"
        return 1
    fi
    
    # Update Redis connection settings
    /usr/bin/sed -i "s/REDIS_HOST=.*/REDIS_HOST=$REDIS_CLOUD_HOST/" "$ENV_FILE"
    /usr/bin/sed -i "s/REDIS_PORT=.*/REDIS_PORT=$REDIS_CLOUD_PORT/" "$ENV_FILE"
    /usr/bin/sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_CLOUD_PASSWORD/" "$ENV_FILE"
    
    log "✅ Redis configuration updated"
    log "📋 New configuration:"
    /usr/bin/grep "REDIS_" "$ENV_FILE" || log "⚠️ Could not display configuration"
}

# Function to restart RedisArena service
restart_service() {
    log "🔄 Restarting RedisArena service..."
    
    if [ -x "/usr/bin/systemctl" ]; then
        # Stop the service first
        log "⏹️ Stopping RedisArena service..."
        sudo /usr/bin/systemctl stop redisarena
        /usr/bin/sleep 2
        
        # Start the service
        log "🚀 Starting RedisArena service..."
        sudo /usr/bin/systemctl start redisarena
        /usr/bin/sleep 5
        
        # Verify it's active
        if /usr/bin/systemctl is-active redisarena >/dev/null 2>&1; then
            log "✅ RedisArena service restarted successfully"
            log "🔗 Service is now active with new configuration"
        else
            log "❌ RedisArena service failed to start"
            log "🔍 Check service logs: journalctl -u redisarena -n 10"
            return 1
        fi
    else
        log "⚠️ systemctl not available"
        return 1
    fi
}

# Function to verify cutover success
verify_cutover() {
    log "🔍 Verifying cutover success..."
    
    # Check if service is responding
    if /usr/bin/command -v curl >/dev/null 2>&1; then
        if /usr/bin/curl -f -s --max-time 10 "http://localhost:5000/api/status" >/dev/null 2>&1; then
            log "✅ RedisArena is responding on port 5000"
            return 0
        else
            log "⚠️ RedisArena may not be responding properly"
            return 1
        fi
    else
        log "⚠️ curl not available for verification"
        return 0
    fi
}

# Function to rollback configuration
rollback() {
    log "🔄 Rolling back configuration..."
    
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$ENV_FILE"
        restart_service
        log "✅ Configuration rolled back"
    else
        log "❌ No backup file found for rollback"
        return 1
    fi
}

# Main execution
main() {
    local operation="${1:-cutover}"
    
    # Debug output
    log "🔧 Debug: Received operation: [$operation]"
    
    case "$operation" in
        validate)
            log "🚀 Starting Redis Cloud validation..."
            validate_redis_cloud
            ;;
        cutover)
            log "🚀 Starting Redis migration cutover process..."
            
            # Step 1: Validate Redis Cloud
            if ! validate_redis_cloud; then
                log "❌ Cutover aborted: Redis Cloud validation failed"
                exit 1
            fi
            
            # Step 2: Backup configuration
            backup_config
            
            # Step 3: Update configuration
            update_redis_config
            
            # Step 4: Restart service
            restart_service
            
            # Step 5: Verify cutover
            if verify_cutover; then
                log "🎉 Cutover completed successfully!"
                log "🔗 RedisArena is now connected to Redis Cloud"
                
                # Show sample keys from new Redis Cloud connection to prove cutover worked
                log "🔍 Verifying data access in Redis Cloud after cutover..."
                if [ -f "$ENV_FILE" ]; then
                    local new_host new_port new_password
                    new_host=$(/usr/bin/grep "REDIS_HOST=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                    new_port=$(/usr/bin/grep "REDIS_PORT=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                    new_password=$(/usr/bin/grep "REDIS_PASSWORD=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                    
                    local new_key_count
                    new_key_count=$(/usr/bin/redis-cli -h "$new_host" -p "$new_port" -a "$new_password" dbsize 2>/dev/null || echo "unknown")
                    log "📊 Redis Cloud now shows $new_key_count keys accessible"
                    
                    if [ "$new_key_count" != "unknown" ] && [ "$new_key_count" -gt 0 ]; then
                        log "🔬 Sample keys now accessible via Redis Cloud:"
                        local sample_keys
                        sample_keys=$(/usr/bin/redis-cli -h "$new_host" -p "$new_port" -a "$new_password" --scan --count 3 2>/dev/null | head -3)
                        if [ -n "$sample_keys" ]; then
                            echo "$sample_keys" | while IFS= read -r key; do
                                if [ -n "$key" ]; then
                                    local key_type
                                    key_type=$(/usr/bin/redis-cli -h "$new_host" -p "$new_port" -a "$new_password" type "$key" 2>/dev/null || echo "unknown")
                                    log "   📄 $key (type: $key_type)"
                                fi
                            done
                        fi
                    fi
                fi
            else
                log "⚠️ Cutover completed but verification failed"
                log "🔧 You may need to check the application manually"
            fi
            ;;
        rollback)
            log "🔄 Starting rollback process..."
            rollback
            ;;
        status)
            log "📊 Current Redis Migration Status:"
            
            # Check current configuration and determine backend
            if [ -f "$ENV_FILE" ]; then
                local current_host
                current_host=$(/usr/bin/grep "REDIS_HOST=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                log "🔗 Current endpoint: $current_host"
                
                # Determine backend type
                if echo "$current_host" | /usr/bin/grep -q "cache.amazonaws.com"; then
                    log "🏠 Backend: ElastiCache"
                elif echo "$current_host" | /usr/bin/grep -q "cloud.rlrcp.com"; then
                    log "☁️ Backend: Redis Cloud"  
                else
                    log "❓ Backend: Unknown"
                fi
                
                # Test current connection health
                local current_port
                current_port=$(/usr/bin/grep "REDIS_PORT=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                local current_password
                current_password=$(/usr/bin/grep "REDIS_PASSWORD=" "$ENV_FILE" | /usr/bin/cut -d'=' -f2)
                
                log "🔧 Testing current connection..."
                if /usr/bin/redis-cli -h "$current_host" -p "$current_port" -a "$current_password" ping >/dev/null 2>&1; then
                    log "✅ Current Redis connection: Healthy"
                else
                    log "❌ Current Redis connection: Unhealthy"
                fi
                
                # Get key count
                local key_count
                key_count=$(/usr/bin/redis-cli -h "$current_host" -p "$current_port" -a "$current_password" dbsize 2>/dev/null || echo "unknown")
                log "📊 Current database has $key_count keys"
                
                # Show sample keys to prove data exists
                if [ "$key_count" != "unknown" ] && [ "$key_count" -gt 0 ]; then
                    log "🔬 Sample keys from current database:"
                    local sample_keys
                    sample_keys=$(/usr/bin/redis-cli -h "$current_host" -p "$current_port" -a "$current_password" --scan --count 5 2>/dev/null | head -5)
                    if [ -n "$sample_keys" ]; then
                        echo "$sample_keys" | while IFS= read -r key; do
                            if [ -n "$key" ]; then
                                local key_type
                                key_type=$(/usr/bin/redis-cli -h "$current_host" -p "$current_port" -a "$current_password" type "$key" 2>/dev/null || echo "unknown")
                                log "   📄 $key (type: $key_type)"
                            fi
                        done
                    else
                        log "   📄 Keys exist but unable to scan"
                    fi
                elif [ "$key_count" = "0" ]; then
                    log "   📄 Database is empty"
                else
                    log "   📄 Unable to access database for key scanning"
                fi
                
            else
                log "❌ No configuration file found at $ENV_FILE"
            fi
            
            # Check RedisArena service status
            if [ -x "/usr/bin/systemctl" ]; then
                if /usr/bin/systemctl is-active redisarena >/dev/null 2>&1; then
                    log "✅ RedisArena service: Active"
                    
                    # Check if application is responding
                    if /usr/bin/curl -f -s --max-time 5 "http://localhost:5000/api/status" >/dev/null 2>&1; then
                        log "✅ RedisArena API: Responding"
                    else
                        log "⚠️ RedisArena API: Not responding"
                    fi
                else
                    log "❌ RedisArena service: Inactive"
                fi
            fi
            ;;
        restart)
            log "🔄 Restarting RedisArena application..."
            restart_service
            ;;
        flush-elasticache)
            log "🧹 Flushing ElastiCache database..."
            
            # Get ElastiCache endpoint from backup or current config
            local elasticache_host
            if [ -f "$BACKUP_FILE" ]; then
                elasticache_host=$(/usr/bin/grep "REDIS_HOST=" "$BACKUP_FILE" | /usr/bin/cut -d'=' -f2)
            else
                # Default ElastiCache endpoint pattern
                elasticache_host="${ELASTICACHE_HOST:-elasticache-example.cache.amazonaws.com}"
            fi
            
            local elasticache_port="6379"
            
            log "📋 Target ElastiCache: $elasticache_host:$elasticache_port"
            
            if [ -x "/usr/bin/redis-cli" ]; then
                # Show what's in ElastiCache before flushing
                log "🔍 Scanning ElastiCache database before flush..."
                local pre_flush_size
                pre_flush_size=$(/usr/bin/redis-cli -h "$elasticache_host" -p "$elasticache_port" dbsize 2>/dev/null || echo "unknown")
                log "📊 ElastiCache currently contains $pre_flush_size keys"
                
                if [ "$pre_flush_size" != "unknown" ] && [ "$pre_flush_size" -gt 0 ]; then
                    log "🔬 Sample keys in ElastiCache before flush:"
                    # Get a few sample keys to prove data exists
                    local sample_keys
                    sample_keys=$(/usr/bin/redis-cli -h "$elasticache_host" -p "$elasticache_port" --scan --count 5 2>/dev/null | head -5)
                    if [ -n "$sample_keys" ]; then
                        echo "$sample_keys" | while IFS= read -r key; do
                            if [ -n "$key" ]; then
                                local key_type
                                key_type=$(/usr/bin/redis-cli -h "$elasticache_host" -p "$elasticache_port" type "$key" 2>/dev/null || echo "unknown")
                                log "   📄 $key (type: $key_type)"
                            fi
                        done
                    else
                        log "   📄 Keys exist but unable to scan"
                    fi
                else
                    log "   📄 ElastiCache appears to be empty already"
                fi
                
                log "🔧 Executing FLUSHALL command..."
                if /usr/bin/redis-cli -h "$elasticache_host" -p "$elasticache_port" flushall; then
                    log "✅ ElastiCache database flushed successfully"
                    
                    # Check key count to confirm
                    local key_count
                    key_count=$(/usr/bin/redis-cli -h "$elasticache_host" -p "$elasticache_port" dbsize)
                    log "📊 ElastiCache now has $key_count keys (should be 0)"
                    
                    if [ "$key_count" = "0" ]; then
                        log "🎉 ElastiCache is completely empty - migration confirmed!"
                    else
                        log "⚠️ ElastiCache still has $key_count keys"
                    fi
                else
                    log "❌ Failed to flush ElastiCache"
                    return 1
                fi
            else
                log "❌ redis-cli not available"
                return 1
            fi
            ;;
        *)
            log "Usage: $0 {validate|cutover|rollback|status|restart|flush-elasticache}"
            log "  validate - Test Redis Cloud connectivity"
            log "  cutover  - Perform migration to Redis Cloud"
            log "  rollback - Revert to previous configuration"
            log "  status   - Show current status"  
            log "  restart  - Restart RedisArena application"
            log "  flush-elasticache - Clear all data from ElastiCache"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"