# Redis Cloud + RIOT Terraform Project

This project creates a complete Redis migration environment with Redis Cloud, AWS VPC infrastructure, and RIOT-X tooling for data migration and replication.

## What This Creates

- **AWS VPC**: Complete networking infrastructure with public/private subnets
- **Redis Cloud**: Managed Redis Enterprise subscription and database
- **VPC Peering**: Secure connection between AWS VPC and Redis Cloud
- **RIOT EC2 Instance**: EC2 instance with RIOT-X tools pre-installed
- **Redis OSS**: Local Redis instance on RIOT server for staging
- **Security Groups**: Properly configured security for all components

## Prerequisites

- AWS CLI configured with appropriate credentials
- Redis Cloud account and API credentials
- Terraform >= 1.0 installed
- EC2 key pair for SSH access
- Valid payment method in Redis Cloud

## Quick Start

1. **Get Redis Cloud API credentials**:
   - Log in to Redis Cloud console
   - Go to Access Management > API Keys
   - Create a new API key and secret

2. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your credentials and settings
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Get connection details**:
   ```bash
   terraform output ssh_command
   terraform output -raw redis_cloud_cli_command
   ```

## Configuration

### Required Variables

- `name_prefix`: Unique prefix for all resources
- `owner`: Your name or team identifier
- `aws_account_id`: Your AWS Account ID (12 digits)
- `key_name`: EC2 key pair name for SSH access
- `ssh_private_key_path`: Path to your SSH private key
- `rediscloud_api_key`: Redis Cloud API key
- `rediscloud_secret_key`: Redis Cloud secret key
- `credit_card_type`: Payment method type
- `credit_card_last_four`: Last 4 digits of payment method

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `riot_instance_type`: RIOT server size (default: t3.xlarge)
- `dataset_size_in_gb`: Expected dataset size (default: 1GB)
- `modules_enabled`: Redis modules (default: ["RedisJSON"])
- `allow_ssh_from`: SSH access CIDRs

## Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   AWS VPC       │    │   Redis Cloud    │
│                 │    │                  │
│ ┌─────────────┐ │    │ ┌──────────────┐ │
│ │ RIOT EC2    │ │◄──►│ │ Redis        │ │
│ │ - RIOT-X    │ │    │ │ Database     │ │
│ │ - Redis OSS │ │    │ │              │ │
│ │ - Grafana   │ │    │ └──────────────┘ │
│ └─────────────┘ │    │                  │
└─────────────────┘    └──────────────────┘
        │                       │
        └───── VPC Peering ─────┘
```

## Usage

### Connecting to RIOT Instance

```bash
# SSH to RIOT instance
terraform output -raw ssh_command | bash

# Once connected, check RIOT-X installation
riotx --version

# Check Redis OSS
redis-cli ping
```

### Connecting to Redis Cloud

```bash
# From your local machine
terraform output -raw redis_cloud_cli_command | bash

# From RIOT instance (using private endpoint)
ssh -i your-key.pem ubuntu@RIOT_IP
redis-cli -h REDIS_CLOUD_PRIVATE_IP -p PORT -a PASSWORD
```

## RIOT-X Migration Examples

### Live Replication (Continuous Sync)

```bash
# SSH to RIOT instance
ssh -i your-key.pem ubuntu@RIOT_IP

# Start live replication from local Redis OSS to Redis Cloud
riotx replicate \
  --source redis://localhost:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT \
  --live
```

### One-time Migration

```bash
# Migrate all data from source to Redis Cloud
riotx replicate \
  --source redis://SOURCE_HOST:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT
```

### Data Generation for Testing

```bash
# Generate test data in local Redis OSS
riotx generate \
  --target redis://localhost:6379 \
  --count 10000 \
  --keyspace person \
  --fields firstname,lastname,email
```

## Monitoring

### Accessing Observability Tools

If observability is enabled on the RIOT instance:

```bash
# Get RIOT instance IP
RIOT_IP=$(terraform output -raw riot_ec2_public_ip)

# Access Grafana (if enabled)
echo "Grafana: http://$RIOT_IP:3000"
echo "Default credentials: admin/admin"

# Access Prometheus (if enabled)
echo "Prometheus: http://$RIOT_IP:9090"
```

### Redis Cloud Monitoring

- **Redis Cloud Console**: https://app.redislabs.com
- Built-in metrics and alerting
- Performance monitoring and insights

## Common Migration Workflows

### 1. ElastiCache to Redis Cloud Migration

```bash
# From RIOT instance
riotx replicate \
  --source redis://ELASTICACHE_ENDPOINT:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT \
  --live \
  --key-filter "*"
```

### 2. On-premises Redis to Redis Cloud

```bash
# One-time migration
riotx replicate \
  --source redis://ONPREM_HOST:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT \
  --batch-size 1000

# With live replication
riotx replicate \
  --source redis://ONPREM_HOST:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT \
  --live \
  --batch-size 1000
```

### 3. Data Validation

```bash
# Compare source and target
riotx compare \
  --source redis://SOURCE_HOST:6379 \
  --target redis://:PASSWORD@REDIS_CLOUD_PRIVATE_IP:PORT
```

## Outputs

Key outputs for connection and management:

- `ssh_command`: Ready-to-use SSH command for RIOT instance
- `redis_cloud_cli_command`: Redis CLI command for Redis Cloud
- `riot_commands`: Common RIOT-X commands for your environment
- `database_private_endpoint`: Private endpoint for VPC-internal connections
- `database_public_endpoint`: Public endpoint for external connections

## Cost Optimization

### AWS Resources
- Use `t3.large` for lighter workloads instead of `t3.xlarge`
- Stop RIOT instance when not actively migrating
- Consider reserved instances for long-term projects

### Redis Cloud
- Start with smaller database sizes and scale up
- Use appropriate throughput settings
- Monitor usage and adjust as needed

## Security Best Practices

1. **Network Security**: All Redis traffic uses private endpoints
2. **Access Control**: Limit SSH access with specific IP CIDRs
3. **Encryption**: Redis Cloud uses encryption in transit and at rest
4. **Key Management**: Store SSH keys and Redis passwords securely

## Troubleshooting

### Common Issues

1. **VPC Peering failed**: Check AWS account ID and permissions
2. **Can't connect to Redis Cloud**: Verify VPC peering and security groups
3. **RIOT commands fail**: Check Redis Cloud password and endpoints
4. **SSH connection refused**: Verify key pair and security group rules

### Useful Commands

```bash
# Check VPC peering status
aws ec2 describe-vpc-peering-connections

# Test Redis Cloud connectivity from RIOT instance
ssh -i your-key.pem ubuntu@RIOT_IP 'redis-cli -h REDIS_IP -p PORT -a PASSWORD ping'

# Check RIOT instance logs
ssh -i your-key.pem ubuntu@RIOT_IP 'sudo tail -f /var/log/user-data.log'
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Note**: This will delete all AWS resources and the Redis Cloud subscription. Make sure to backup any important data first.

## Advanced Usage

### Custom RIOT Scripts

You can create custom migration scripts on the RIOT instance:

```bash
# SSH to RIOT instance
ssh -i your-key.pem ubuntu@RIOT_IP

# Create custom migration script
cat > migrate.sh << 'EOF'
#!/bin/bash
riotx replicate \
  --source redis://SOURCE:6379 \
  --target redis://:PASSWORD@TARGET:PORT \
  --live \
  --progress \
  --batch-size 1000
EOF

chmod +x migrate.sh
./migrate.sh
```

## Support

- RIOT-X Documentation: https://github.com/redis-field-engineering/riot
- Redis Cloud Documentation: https://docs.redis.com/
- AWS VPC Documentation: https://docs.aws.amazon.com/vpc/