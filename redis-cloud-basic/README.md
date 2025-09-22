# Redis Cloud-Only Terraform Project

This project creates a standalone Redis Cloud subscription and database without any AWS infrastructure.

## What This Creates

- **Redis Cloud Subscription**: Managed Redis Enterprise subscription
- **Redis Database**: Fully managed Redis database with configurable settings
- **Security**: Encrypted connections and authentication
- **High Availability**: Multi-AZ deployment option
- **Modules**: Redis modules like RedisJSON, RediSearch, etc.

## Prerequisites

- Redis Cloud account and API credentials
- Terraform >= 1.0 installed
- Valid payment method configured in Redis Cloud

## Quick Start

1. **Get Redis Cloud API credentials**:
   - Log in to Redis Cloud console
   - Go to Access Management > API Keys
   - Create a new API key and secret

2. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your Redis Cloud credentials
   ```

3. **Deploy Redis Cloud**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Get connection details**:
   ```bash
   terraform output database_public_endpoint
   terraform output -raw rediscloud_password
   ```

## Configuration

### Required Variables

- `owner`: Your name or team identifier
- `rediscloud_api_key`: Redis Cloud API key
- `rediscloud_secret_key`: Redis Cloud secret key
- `credit_card_type`: Payment method type
- `credit_card_last_four`: Last 4 digits of payment method

### Optional Variables

- `subscription_name`: Name for the subscription
- `database_name`: Name for the database
- `rediscloud_region`: Deployment region (default: us-west-2)
- `dataset_size_in_gb`: Expected dataset size (default: 1GB)
- `throughput_value`: Expected ops/sec (default: 1000)
- `modules_enabled`: Redis modules to enable (default: ["RedisJSON"])
- `multi_az`: High availability across AZs (default: true)
- `data_persistence`: Persistence mode (default: aof-every-1-second)

## Outputs

The module provides these connection details:

- `database_public_endpoint`: Public endpoint for connections
- `database_private_endpoint`: Private endpoint (for VPC peering)
- `rediscloud_password`: Database password (sensitive)
- `redis_connection_string`: Complete connection string (sensitive)
- `subscription_status`: Subscription status

## Connecting to Your Database

### Using Redis CLI

```bash
# Get connection details
ENDPOINT=$(terraform output -raw database_public_endpoint)
PASSWORD=$(terraform output -raw rediscloud_password)

# Connect with redis-cli
redis-cli -h $(echo $ENDPOINT | cut -d: -f1) -p $(echo $ENDPOINT | cut -d: -f2) -a $PASSWORD
```

### Using Application Code

```python
import redis

# Get outputs from terraform
endpoint = "your-endpoint:port"
password = "your-password"

# Connect
r = redis.Redis.from_url(f"redis://:{password}@{endpoint}")
r.ping()
```

## Monitoring and Management

- **Redis Cloud Console**: https://app.redislabs.com
- **Metrics**: Built-in monitoring and alerting
- **Backup**: Automatic backup and recovery
- **Scaling**: Easy horizontal and vertical scaling

## Cost Optimization

- Start with smaller instance sizes and scale up as needed
- Use appropriate persistence settings for your use case
- Monitor usage and adjust throughput settings
- Consider data retention policies

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Invalid API credentials**: Verify your API key and secret
2. **Payment method required**: Add valid payment method in Redis Cloud console
3. **Region availability**: Check if your preferred region supports Redis Cloud
4. **Quota limits**: Verify subscription limits in Redis Cloud console

### Support

- Redis Cloud Documentation: https://docs.redis.com/
- Redis Cloud Support: Available through the console