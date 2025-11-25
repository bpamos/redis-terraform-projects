#!/bin/bash

# =============================================================================
# EC2 Test Instance Setup Script
# Installs Redis CLI and memtier_benchmark for Redis Enterprise testing
# =============================================================================

exec > /var/log/user-data.log 2>&1
set -e

# Configuration variables (injected by Terraform)
REDIS_ENDPOINT="${redis_endpoint}"
REDIS_PASSWORD="${redis_password}"
RETRY_ATTEMPTS=5
RETRY_DELAY=10

echo "=== Starting EC2 Test instance setup ==="
echo "Redis Endpoint: $REDIS_ENDPOINT"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

retry() {
  local n=0
  local cmd="$@"
  until [ $n -ge $RETRY_ATTEMPTS ]; do
    if $cmd; then
      return 0
    fi
    n=$((n+1))
    echo "Attempt $n failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  done
  echo "Command failed after $RETRY_ATTEMPTS attempts: $cmd"
  return 1
}

verify_service() {
  local service_name="$1"
  local test_command="$2"

  echo "Verifying $service_name..."
  if eval "$test_command"; then
    echo "✅ $service_name is working correctly"
    return 0
  else
    echo "❌ $service_name verification failed"
    return 1
  fi
}

# =============================================================================
# SYSTEM SETUP
# =============================================================================

echo "--- Updating system packages ---"
retry sudo apt-get update -y
retry sudo apt-get install -y curl wget lsb-release gpg

# =============================================================================
# REDIS APT REPOSITORY SETUP
# =============================================================================

echo "--- Setting up Redis APT repository ---"
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
retry sudo apt-get update -y

# =============================================================================
# REDIS TOOLS INSTALLATION
# =============================================================================

echo "--- Installing Redis tools from official repository ---"
retry sudo apt-get install -y redis-tools memtier-benchmark

verify_service "Redis CLI" "redis-cli --version | grep -q redis-cli" || exit 1
verify_service "memtier_benchmark" "memtier_benchmark --version | grep -q memtier_benchmark" || exit 1

# =============================================================================
# CREATE TEST SCRIPTS
# =============================================================================

echo "--- Creating test scripts ---"

# Create Redis connection test script
cat << 'EOF' > /home/ubuntu/test-redis-connection.sh
#!/bin/bash

ENDPOINT="$1"
PASSWORD="$2"

if [ -z "$ENDPOINT" ]; then
  echo "Usage: $0 <redis-endpoint> [password]"
  echo "Example: $0 redis-12000.cluster.redisdemo.com:12000"
  echo "Example: $0 10.0.1.10:12000 mypassword"
  exit 1
fi

HOST=$(echo $ENDPOINT | cut -d: -f1)
PORT=$(echo $ENDPOINT | cut -d: -f2)

echo "Testing Redis connection to $HOST:$PORT..."

if [ -n "$PASSWORD" ]; then
  redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning ping
else
  redis-cli -h "$HOST" -p "$PORT" ping
fi

if [ $? -eq 0 ]; then
  echo "✅ Redis connection successful!"
  echo "Testing basic operations..."
  if [ -n "$PASSWORD" ]; then
    redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning SET test:key "Hello from test node"
    redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning GET test:key
  else
    redis-cli -h "$HOST" -p "$PORT" SET test:key "Hello from test node"
    redis-cli -h "$HOST" -p "$PORT" GET test:key
  fi
else
  echo "❌ Redis connection failed"
  exit 1
fi
EOF

# Create memtier benchmark script
cat << 'EOF' > /home/ubuntu/run-memtier-benchmark.sh
#!/bin/bash

ENDPOINT="$1"
PASSWORD="$2"
DURATION="$${3:-60}"

if [ -z "$ENDPOINT" ]; then
  echo "Usage: $0 <redis-endpoint> [password] [duration-seconds]"
  echo "Example: $0 redis-12000.cluster.redisdemo.com:12000"
  echo "Example: $0 10.0.1.10:12000 mypassword 60"
  exit 1
fi

HOST=$(echo $ENDPOINT | cut -d: -f1)
PORT=$(echo $ENDPOINT | cut -d: -f2)

echo "Running memtier_benchmark against $HOST:$PORT for $DURATION seconds..."

if [ -n "$PASSWORD" ]; then
  memtier_benchmark \
    -s "$HOST" \
    -p "$PORT" \
    -a "$PASSWORD" \
    --protocol redis \
    --clients=10 \
    --threads=2 \
    --test-time="$DURATION" \
    --ratio=1:1 \
    --pipeline=4 \
    --key-pattern=R:R \
    --key-prefix=test: \
    --data-size-range=60-1024 \
    --expiry-range=60-60 \
    --random-data \
    --distinct-client-seed \
    --hide-histogram
else
  memtier_benchmark \
    -s "$HOST" \
    -p "$PORT" \
    --protocol redis \
    --clients=10 \
    --threads=2 \
    --test-time="$DURATION" \
    --ratio=1:1 \
    --pipeline=4 \
    --key-pattern=R:R \
    --key-prefix=test: \
    --data-size-range=60-1024 \
    --expiry-range=60-60 \
    --random-data \
    --distinct-client-seed \
    --hide-histogram
fi
EOF

# Make scripts executable
chmod +x /home/ubuntu/test-redis-connection.sh
chmod +x /home/ubuntu/run-memtier-benchmark.sh
chown ubuntu:ubuntu /home/ubuntu/*.sh

# =============================================================================
# TEST REDIS CONNECTION (if endpoint provided)
# =============================================================================

if [ -n "$REDIS_ENDPOINT" ]; then
  echo "--- Testing Redis Enterprise connection ---"
  HOST=$(echo $REDIS_ENDPOINT | cut -d: -f1)
  PORT=$(echo $REDIS_ENDPOINT | cut -d: -f2)

  echo "Testing connection to Redis Enterprise at $HOST:$PORT..."
  if [ -n "$REDIS_PASSWORD" ]; then
    redis-cli -h "$HOST" -p "$PORT" -a "$REDIS_PASSWORD" --no-auth-warning ping
  else
    redis-cli -h "$HOST" -p "$PORT" ping
  fi

  if [ $? -eq 0 ]; then
    echo "✅ Redis Enterprise connection successful!"
  else
    echo "⚠️  Redis Enterprise connection failed - this is normal if database is not yet ready"
  fi
fi

# =============================================================================
# SETUP COMPLETE
# =============================================================================

echo "=== Setup Complete ==="
echo "🔧 Redis CLI:        Available via 'redis-cli' command"
echo "📊 memtier_benchmark: Available via 'memtier_benchmark' command"
echo "🧪 Test Scripts:"
echo "   - /home/ubuntu/test-redis-connection.sh <endpoint> [password]"
echo "   - /home/ubuntu/run-memtier-benchmark.sh <endpoint> [password] [duration]"
echo "📝 Logs:             /var/log/user-data.log"
echo ""
echo "Example usage:"
echo "  ./test-redis-connection.sh redis-12000-internal.cluster.redisdemo.com:12000"
echo "  ./run-memtier-benchmark.sh 10.0.1.10:12000 \"\" 60"
