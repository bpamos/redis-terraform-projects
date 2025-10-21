# RIOT Tooling-Only Terraform Project

This project creates a standalone RIOT-X migration environment with AWS VPC infrastructure and a pre-configured EC2 instance containing all Redis migration tools.

## What This Creates

- **AWS VPC**: Complete networking infrastructure with public/private subnets
- **RIOT EC2 Instance**: EC2 instance with RIOT-X tools pre-installed
- **Redis OSS**: Local Redis instance for staging and testing
- **Migration Tools**: Complete toolkit for Redis data migration
- **Observability**: Optional Prometheus and Grafana for monitoring
- **Security Groups**: Properly configured security for all components

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- EC2 key pair for SSH access

## Quick Start

1. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your AWS credentials and settings
   ```

2. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Connect to your RIOT instance**:
   ```bash
   terraform output -raw ssh_command | bash
   ```

4. **Verify installation**:
   ```bash
   # Check RIOT-X version
   riotx --version
   
   # Check Redis OSS
   redis-cli ping
   ```

## Configuration

### Required Variables

- `name_prefix`: Unique prefix for all resources
- `owner`: Your name or team identifier
- `key_name`: EC2 key pair name for SSH access
- `ssh_private_key_path`: Path to your SSH private key

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `riot_instance_type`: Instance size (default: t3.xlarge)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `allow_ssh_from`: SSH access CIDRs

## What's Included

### Pre-installed Tools

- **RIOT-X**: Latest version for Redis data migration
- **Redis OSS**: Local Redis instance for staging data
- **Redis CLI**: Command-line interface for Redis operations
- **Docker**: Container runtime for additional tools
- **Docker Compose**: For multi-container applications

### Optional Observability Stack

If enabled in the RIOT module:
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **Pre-configured**: Ready-to-use monitoring setup

## Usage Examples

### Basic RIOT Operations

```bash
# SSH to your RIOT instance
terraform output -raw ssh_command | bash

# Generate test data in local Redis OSS
riotx generate \
  --target redis://localhost:6379 \
  --count 10000 \
  --keyspace person \
  --fields firstname,lastname,email

# Migrate data between Redis instances
riotx replicate \
  --source redis://source-host:6379 \
  --target redis://target-host:6379
```

### Live Replication

```bash
# Start continuous replication
riotx replicate \
  --source redis://source-host:6379 \
  --target redis://target-host:6379 \
  --live \
  --progress

# With authentication
riotx replicate \
  --source redis://:password@source-host:6379 \
  --target redis://:password@target-host:6379 \
  --live
```

### Data Import/Export

```bash
# Export Redis data to file
riotx export \
  --source redis://localhost:6379 \
  --target file:///tmp/redis-backup.json

# Import data from file
riotx import \
  --source file:///tmp/redis-backup.json \
  --target redis://localhost:6379
```

### ElastiCache Migration

```bash
# Migrate from ElastiCache to Redis Cloud
riotx replicate \
  --source redis://your-elasticache-endpoint:6379 \
  --target redis://:password@redis-cloud-endpoint:port \
  --live \
  --batch-size 1000
```

## Outputs

Key outputs for connecting and using your RIOT environment:

- `ssh_command`: Ready-to-use SSH command
- `riot_ec2_public_ip`: Public IP of RIOT instance
- `useful_commands`: Collection of common RIOT commands
- `monitoring_urls`: Access URLs for Grafana and Prometheus (if enabled)

## Monitoring and Observability

### Accessing Monitoring Tools

```bash
# Get instance IP
RIOT_IP=$(terraform output -raw riot_ec2_public_ip)

# Access Grafana (if enabled)
echo "Grafana: http://$RIOT_IP:3000"
echo "Default credentials: admin/admin"

# Access Prometheus (if enabled)
echo "Prometheus: http://$RIOT_IP:9090"
```

### Redis OSS Monitoring

```bash
# Connect to your RIOT instance
ssh -i your-key.pem ubuntu@$(terraform output -raw riot_ec2_public_ip)

# Monitor Redis OSS
redis-cli info
redis-cli monitor
redis-cli --latency
```

## Migration Patterns

### 1. Staging Environment

Use the local Redis OSS as a staging area:

```bash
# Load data into staging
riotx replicate \
  --source redis://production-source:6379 \
  --target redis://localhost:6379

# Test and validate data
redis-cli -h localhost -p 6379

# Migrate to final destination
riotx replicate \
  --source redis://localhost:6379 \
  --target redis://final-destination:6379
```

### 2. Data Transformation

Transform data during migration:

```bash
# Migrate with key prefix transformation
riotx replicate \
  --source redis://source:6379 \
  --target redis://target:6379 \
  --key-filter "old:*" \
  --key-regex "old:(.*)" \
  --key-replacement "new:\$1"
```

### 3. Selective Migration

Migrate only specific data:

```bash
# Migrate specific key patterns
riotx replicate \
  --source redis://source:6379 \
  --target redis://target:6379 \
  --key-filter "user:*" \
  --key-filter "session:*"
```

## Instance Sizing Guide

### t3.medium (4GB RAM)
- **Use for**: Small datasets, testing, development
- **Redis OSS Memory**: ~2-3GB available
- **Suitable for**: < 1GB datasets

### t3.large (8GB RAM)
- **Use for**: Medium datasets, production migrations
- **Redis OSS Memory**: ~5-6GB available
- **Suitable for**: 1-4GB datasets

### t3.xlarge (16GB RAM)
- **Use for**: Large datasets, complex migrations
- **Redis OSS Memory**: ~12-14GB available
- **Suitable for**: 4-10GB datasets

### t3.2xlarge (32GB RAM)
- **Use for**: Very large datasets, enterprise migrations
- **Redis OSS Memory**: ~25-28GB available
- **Suitable for**: 10-20GB datasets

## Cost Optimization

- **Start small**: Use t3.medium for testing, scale up for production
- **Stop when idle**: Stop the instance when not actively migrating
- **Spot instances**: Consider spot instances for non-critical migrations
- **Reserved instances**: Use reserved instances for long-term projects

## Security Best Practices

1. **SSH Access**: Limit SSH access to specific IP ranges
2. **Key Management**: Store SSH keys securely
3. **Network Isolation**: RIOT instance is in a dedicated VPC
4. **Regular Updates**: Keep the instance updated with security patches

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   
   # Verify key permissions
   chmod 400 your-key.pem
   ```

2. **RIOT Commands Fail**
   ```bash
   # Check RIOT installation
   ssh -i your-key.pem ubuntu@RIOT_IP 'which riotx'
   
   # Check Redis OSS status
   ssh -i your-key.pem ubuntu@RIOT_IP 'sudo systemctl status redis-server'
   ```

3. **Out of Memory Errors**
   ```bash
   # Check memory usage
   ssh -i your-key.pem ubuntu@RIOT_IP 'free -h'
   
   # Scale up instance type in terraform.tfvars
   riot_instance_type = "t3.2xlarge"
   terraform apply
   ```

### Useful Commands

```bash
# View instance logs
ssh -i your-key.pem ubuntu@RIOT_IP 'sudo tail -f /var/log/user-data.log'

# Restart Redis OSS
ssh -i your-key.pem ubuntu@RIOT_IP 'sudo systemctl restart redis-server'

# Check disk space
ssh -i your-key.pem ubuntu@RIOT_IP 'df -h'
```

## Integration with Other Projects

This RIOT tooling can be used with other projects:

### With ElastiCache-Only Project
```bash
# Get ElastiCache endpoint from other project
ELASTICACHE_ENDPOINT=$(cd ../elasticache-only && terraform output -raw elasticache_primary_endpoint)

# Migrate from ElastiCache
riotx replicate \
  --source redis://$ELASTICACHE_ENDPOINT:6379 \
  --target redis://target:6379
```

### With Redis Cloud-Only Project
```bash
# Get Redis Cloud details from other project
cd ../redis-cloud-only
REDIS_ENDPOINT=$(terraform output -raw database_public_endpoint)
REDIS_PASSWORD=$(terraform output -raw rediscloud_password)

# Migrate to Redis Cloud
riotx replicate \
  --source redis://localhost:6379 \
  --target redis://:$REDIS_PASSWORD@$REDIS_ENDPOINT
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Advanced Usage

### Custom Migration Scripts

Create custom scripts for complex migrations:

```bash
# SSH to RIOT instance
ssh -i your-key.pem ubuntu@RIOT_IP

# Create migration script
cat > complex_migration.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting complex migration..."

# Step 1: Initial data load
riotx replicate \
  --source redis://source:6379 \
  --target redis://localhost:6379 \
  --progress

# Step 2: Transform data
redis-cli --eval transform.lua

# Step 3: Final migration
riotx replicate \
  --source redis://localhost:6379 \
  --target redis://destination:6379 \
  --progress

echo "Migration completed successfully!"
EOF

chmod +x complex_migration.sh
./complex_migration.sh
```

## Support

- RIOT-X Documentation: https://github.com/redis-field-engineering/riot
- Redis Documentation: https://redis.io/documentation
- AWS EC2 Documentation: https://docs.aws.amazon.com/ec2/