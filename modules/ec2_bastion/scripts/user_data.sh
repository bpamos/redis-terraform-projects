#!/bin/bash

# =============================================================================
# EC2 Bastion Instance Setup Script
# Installs Redis tools, kubectl, AWS CLI, and other utilities
# =============================================================================

exec > /var/log/user-data.log 2>&1
set -e

# Configuration variables (injected by Terraform)
REDIS_ENDPOINTS='${redis_endpoints}'
INSTALL_KUBECTL='${install_kubectl}'
INSTALL_AWS_CLI='${install_aws_cli}'
INSTALL_DOCKER='${install_docker}'
EKS_CLUSTER_NAME='${eks_cluster_name}'
AWS_REGION='${aws_region}'
RETRY_ATTEMPTS=5
RETRY_DELAY=10

echo "=== Starting EC2 Bastion instance setup ==="
echo "Configuration:"
echo "  Install kubectl: $INSTALL_KUBECTL"
echo "  Install AWS CLI: $INSTALL_AWS_CLI"
echo "  Install Docker: $INSTALL_DOCKER"
echo "  EKS Cluster: $EKS_CLUSTER_NAME"
echo "  AWS Region: $AWS_REGION"

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
retry sudo apt-get install -y curl wget lsb-release gpg jq unzip git

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
# KUBECTL INSTALLATION (Optional)
# =============================================================================

if [ "$INSTALL_KUBECTL" = "true" ]; then
  echo "--- Installing kubectl ---"

  # Download latest stable kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl

  verify_service "kubectl" "kubectl version --client | grep -q Client" || exit 1

  # Configure EKS cluster access if cluster name provided
  if [ -n "$EKS_CLUSTER_NAME" ] && [ -n "$AWS_REGION" ]; then
    echo "--- Configuring kubectl for EKS cluster: $EKS_CLUSTER_NAME ---"

    # Wait for IAM instance profile credentials to be available (up to 30 seconds)
    echo "Waiting for IAM instance profile credentials..."
    retry_count=0
    max_retries=6
    while [ $retry_count -lt $max_retries ]; do
      if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /dev/null 2>&1; then
        echo "✅ IAM credentials available"
        break
      fi
      retry_count=$((retry_count + 1))
      echo "Waiting for IAM credentials... ($retry_count/$max_retries)"
      sleep 5
    done

    # Configure kubectl for ubuntu user
    echo "Configuring kubectl for EKS cluster: $EKS_CLUSTER_NAME"
    sudo -u ubuntu aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME 2>&1

    if [ $? -eq 0 ]; then
      echo "✅ kubectl configured successfully for EKS cluster: $EKS_CLUSTER_NAME"

      # Test kubectl access
      echo "Testing kubectl access..."
      if sudo -u ubuntu kubectl get nodes > /dev/null 2>&1; then
        echo "✅ kubectl can access EKS cluster"
        sudo -u ubuntu kubectl get nodes
      else
        echo "⚠️  kubectl configured but cluster not yet accessible (this is normal if cluster is still being created)"
      fi
    else
      echo "⚠️  kubectl configuration failed - IAM credentials may not be available yet"
      echo "You can manually configure kubectl later by running:"
      echo "  aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME"
    fi
  fi
fi

# =============================================================================
# AWS CLI INSTALLATION (Optional)
# =============================================================================

if [ "$INSTALL_AWS_CLI" = "true" ]; then
  echo "--- Installing AWS CLI v2 ---"

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip

  verify_service "AWS CLI" "aws --version | grep -q aws-cli" || exit 1

  # Configure default region if provided
  if [ -n "$AWS_REGION" ]; then
    sudo -u ubuntu mkdir -p /home/ubuntu/.aws
    echo "[default]" | sudo -u ubuntu tee /home/ubuntu/.aws/config > /dev/null
    echo "region = $AWS_REGION" | sudo -u ubuntu tee -a /home/ubuntu/.aws/config > /dev/null
    echo "✅ AWS CLI configured with default region: $AWS_REGION"
  fi
fi

# =============================================================================
# DOCKER INSTALLATION (Optional)
# =============================================================================

if [ "$INSTALL_DOCKER" = "true" ]; then
  echo "--- Installing Docker ---"

  # Add Docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # Set up Docker repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  retry sudo apt-get update -y
  retry sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Add ubuntu user to docker group
  sudo usermod -aG docker ubuntu

  verify_service "Docker" "docker --version | grep -q Docker" || exit 1
fi

# =============================================================================
# SAVE REDIS ENDPOINTS CONFIGURATION
# =============================================================================

echo "--- Saving Redis endpoints configuration ---"
echo "$REDIS_ENDPOINTS" | jq '.' > /home/ubuntu/redis-endpoints.json 2>/dev/null || echo '{}' > /home/ubuntu/redis-endpoints.json
chown ubuntu:ubuntu /home/ubuntu/redis-endpoints.json
chmod 600 /home/ubuntu/redis-endpoints.json

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
  echo ""
  echo "Pre-configured endpoints available in redis-endpoints.json"
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
    redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning SET test:key "Hello from bastion"
    redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning GET test:key
    redis-cli -h "$HOST" -p "$PORT" -a "$PASSWORD" --no-auth-warning DEL test:key
  else
    redis-cli -h "$HOST" -p "$PORT" SET test:key "Hello from bastion"
    redis-cli -h "$HOST" -p "$PORT" GET test:key
    redis-cli -h "$HOST" -p "$PORT" DEL test:key
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
  echo ""
  echo "Pre-configured endpoints available in redis-endpoints.json"
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
# TEST REDIS CONNECTIONS (if endpoints provided)
# =============================================================================

if [ "$REDIS_ENDPOINTS" != "{}" ] && [ "$REDIS_ENDPOINTS" != "null" ]; then
  echo "--- Testing pre-configured Redis endpoints ---"

  # Extract and test each endpoint
  echo "$REDIS_ENDPOINTS" | jq -r 'to_entries[] | "\(.key)|\(.value.endpoint)|\(.value.password)"' | while IFS='|' read -r name endpoint password; do
    echo "Testing $name at $endpoint..."
    HOST=$(echo $endpoint | cut -d: -f1)
    PORT=$(echo $endpoint | cut -d: -f2)

    if [ -n "$password" ] && [ "$password" != "null" ]; then
      redis-cli -h "$HOST" -p "$PORT" -a "$password" --no-auth-warning ping 2>&1
    else
      redis-cli -h "$HOST" -p "$PORT" ping 2>&1
    fi

    if [ $? -eq 0 ]; then
      echo "✅ $name connection successful!"
    else
      echo "⚠️  $name connection failed - this is normal if database is not yet ready"
    fi
  done
fi

# =============================================================================
# SETUP COMPLETE
# =============================================================================

echo ""
echo "==================================================================="
echo "=== EC2 Bastion Setup Complete ==="
echo "==================================================================="
echo ""
echo "🔧 Installed Tools:"
echo "   ✅ Redis CLI:        redis-cli"
echo "   ✅ memtier_benchmark: memtier_benchmark"
[ "$INSTALL_KUBECTL" = "true" ] && echo "   ✅ kubectl:          kubectl"
[ "$INSTALL_AWS_CLI" = "true" ] && echo "   ✅ AWS CLI:          aws"
[ "$INSTALL_DOCKER" = "true" ] && echo "   ✅ Docker:           docker"
echo ""
echo "🧪 Test Scripts:"
echo "   - /home/ubuntu/test-redis-connection.sh <endpoint> [password]"
echo "   - /home/ubuntu/run-memtier-benchmark.sh <endpoint> [password] [duration]"
echo ""
[ "$INSTALL_KUBECTL" = "true" ] && [ -n "$EKS_CLUSTER_NAME" ] && echo "⚙️  kubectl automatically configured for EKS cluster: $EKS_CLUSTER_NAME"
[ "$INSTALL_KUBECTL" = "true" ] && [ -n "$EKS_CLUSTER_NAME" ] && echo ""
echo "📝 Configuration Files:"
echo "   - /home/ubuntu/redis-endpoints.json (pre-configured Redis endpoints)"
echo "   - /var/log/user-data.log (setup logs)"
[ "$INSTALL_KUBECTL" = "true" ] && echo "   - /home/ubuntu/.kube/config (kubectl configuration)"
echo ""
echo "📋 Example Usage:"
echo "   ./test-redis-connection.sh redis.example.com:12000 mypassword"
echo "   ./run-memtier-benchmark.sh 10.0.1.10:12000 mypassword 60"
[ "$INSTALL_KUBECTL" = "true" ] && echo "   kubectl get pods -n redis-enterprise"
[ "$INSTALL_KUBECTL" = "true" ] && echo "   kubectl get svc -n redis-enterprise"
[ "$INSTALL_AWS_CLI" = "true" ] && echo "   aws eks list-clusters --region us-west-2"
echo ""
echo "==================================================================="
