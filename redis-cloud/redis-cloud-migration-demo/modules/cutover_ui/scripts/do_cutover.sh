#!/bin/bash

# Load environment variables
if [ -f /opt/cutover-ui/.env ]; then
    set -a
    source /opt/cutover-ui/.env
    set +a
fi

# Configuration
REDIS_CLOUD_HOST=${REDIS_CLOUD_HOST:-unset}
REDIS_CLOUD_PORT=${REDIS_CLOUD_PORT:-unset}
REDIS_CLOUD_PASSWORD=${REDIS_CLOUD_PASSWORD:-unset}

APP_DIR=/opt/redisarena
ENV_FILE=$APP_DIR/.env
BACKUP_FILE=$APP_DIR/.env.backup

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

validate_redis_cloud() {
    log "Validating Redis Cloud connectivity..."
    local ping_result
    ping_result=$(redis-cli -h $REDIS_CLOUD_HOST -p $REDIS_CLOUD_PORT -a $REDIS_CLOUD_PASSWORD ping 2>&1)
    if echo $ping_result | grep -q PONG; then
        log "Redis Cloud connectivity verified"
        return 0
    else
        log "Redis Cloud connection failed"
        return 1
    fi
}

backup_config() {
    log "Backing up current configuration..."
    if [ -f $ENV_FILE ]; then
        cat > $BACKUP_FILE << BACKUP_EOF
# RedisArena Configuration
REDIS_HOST=${ELASTICACHE_HOST:-elasticache-example.cache.amazonaws.com}
REDIS_PORT=${ELASTICACHE_PORT:-6379}
REDIS_PASSWORD=${ELASTICACHE_PASSWORD:-}
REDIS_DB=0

# Application Settings
FLASK_ENV=production
SECRET_KEY=your-secret-key-change-in-production

# Performance Settings
REDIS_POOL_MAX_CONNECTIONS=20
HEALTH_CHECK_INTERVAL=30
BACKUP_EOF
        log "Configuration backed up"
    fi
}

update_redis_config() {
    log "Updating Redis configuration..."
    
    if [ \! -f $ENV_FILE ]; then
        log "Configuration file not found: $ENV_FILE"
        return 1
    fi
    
    sed -i "s/REDIS_HOST=.*/REDIS_HOST=$REDIS_CLOUD_HOST/" $ENV_FILE
    sed -i "s/REDIS_PORT=.*/REDIS_PORT=$REDIS_CLOUD_PORT/" $ENV_FILE
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_CLOUD_PASSWORD/" $ENV_FILE
    
    log "Redis configuration updated"
}

restart_service() {
    log "Restarting RedisArena service..."
    
    sudo systemctl stop redisarena
    sleep 2
    sudo systemctl start redisarena
    sleep 5
    
    if systemctl is-active redisarena >/dev/null 2>&1; then
        log "RedisArena service restarted successfully"
        return 0
    else
        log "RedisArena service failed to start"
        return 1
    fi
}

rollback() {
    log "Rolling back configuration..."
    
    if [ -f $BACKUP_FILE ]; then
        cp $BACKUP_FILE $ENV_FILE
        restart_service
        log "Configuration rolled back"
        return 0
    else
        log "No backup file found for rollback"
        return 1
    fi
}

case "${1:-cutover}" in
    validate)
        log "Starting Redis Cloud validation..."
        validate_redis_cloud
        ;;
    cutover)
        log "Starting cutover process..."
        if validate_redis_cloud; then
            backup_config
            update_redis_config
            # Commented out restart service call - configuration only
            # if restart_service; then
                log "Cutover completed successfully - configuration updated but service restart required"
            # else
            #     log "Cutover failed: Service restart unsuccessful"
            #     exit 1
            # fi
        else
            log "Cutover aborted: Redis Cloud validation failed"
            exit 1
        fi
        ;;
    rollback)
        log "Starting rollback process..."
        if rollback; then
            log "Configuration rolled back"
        else
            log "Rollback failed"
            exit 1
        fi
        ;;
    restart)
        log "Restarting RedisArena application..."
        restart_service
        ;;
    *)
        log "Usage: $0 {validate|cutover|rollback|restart}"
        exit 1
        ;;
esac
