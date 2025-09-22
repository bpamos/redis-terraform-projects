# Redis Cloud + AWS VPC Peering

## TL;DR
Production-ready Terraform boilerplate that creates Redis Cloud subscription + AWS VPC + secure VPC peering. Modular architecture lets you easily add multiple databases or subscriptions. Just add your Redis Cloud API keys and deploy.

```bash
cp terraform.tfvars.example terraform.tfvars  # Add your Redis Cloud API keys
terraform init && terraform apply             # Deploy everything
terraform output redis_cloud_cli_command      # Get connection details
```

## Overview

This project creates a Redis Cloud deployment with AWS VPC infrastructure and secure VPC peering for private connectivity.

## What This Creates

- **AWS VPC**: Complete networking infrastructure with public/private subnets
- **Redis Cloud**: Managed Redis Enterprise subscription and database  
- **VPC Peering**: Secure private connection between AWS VPC and Redis Cloud

## Prerequisites

- AWS CLI configured with appropriate credentials
- Redis Cloud account and API credentials
- Terraform >= 1.0 installed
- Valid payment method in Redis Cloud

## Quick Start

1. **Get Redis Cloud API credentials**:
   - Sign in to Redis Cloud console (https://app.redislabs.com)
   - Go to "Access Management" > "API Keys" tab
   - **Account Key**: Click "Show" then "Copy" (this is your API key)
   - **User Key**: Click "Add", provide name, select user role, click "Create"
   - Copy the user key immediately - it's only shown once (this is your secret key)

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
   terraform output redis_cloud_connection_info
   terraform output -raw redis_cloud_cli_command
   ```

## Configuration

### Required Variables

- `name_prefix`: Unique prefix for all resources
- `owner`: Your name or team identifier
- `aws_account_id`: Your AWS Account ID (12 digits)
- `rediscloud_api_key`: Redis Cloud API key
- `rediscloud_secret_key`: Redis Cloud secret key
- `credit_card_type`: Payment method type (for credit card billing)
- `credit_card_last_four`: Last 4 digits of payment method (for credit card billing)
- Alternatively, use `payment_method = "marketplace"` for AWS Marketplace billing

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `dataset_size_in_gb`: Expected dataset size (default: 1GB)
- `modules_enabled`: Redis modules (default: ["RedisJSON", "RediSearch"])
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   AWS VPC       │    │   Redis Cloud    │
│   10.0.0.0/16   │    │   10.42.0.0/24   │
│                 │    │                  │
│ ┌─────────────┐ │    │ ┌──────────────┐ │
│ │ Private     │ │◄──►│ │ Redis        │ │
│ │ Subnets     │ │    │ │ Database     │ │
│ │             │ │    │ │              │ │
│ └─────────────┘ │    │ └──────────────┘ │
│ ┌─────────────┐ │    │                  │
│ │ Public      │ │    │                  │
│ │ Subnets     │ │    │                  │
│ └─────────────┘ │    │                  │
└─────────────────┘    └──────────────────┘
        │                       │
        └───── VPC Peering ─────┘
```

## Usage

### Connecting to Redis Cloud

From any EC2 instance in your VPC private subnets:

```bash
# Using private endpoint (recommended for VPC-internal connections)
redis-cli -h REDIS_CLOUD_PRIVATE_IP -p PORT -a PASSWORD

# Using public endpoint (for external connections)
redis-cli -h REDIS_CLOUD_PUBLIC_IP -p PORT -a PASSWORD
```

Get connection details:
```bash
# Get all connection information
terraform output redis_cloud_connection_info

# Get ready-to-use CLI command
terraform output -raw redis_cloud_cli_command
```

### Network Configuration

**Option 1: Create New VPC (Default)**
- **AWS VPC**: 10.0.0.0/16
  - Public subnets: 10.0.1.0/24, 10.0.2.0/24
  - Private subnets: 10.0.3.0/24, 10.0.4.0/24
- **Redis Cloud**: 10.42.0.0/24
- **VPC Peering**: Automatic setup with route configuration

**Option 2: Use Existing VPC**
- Comment out the VPC configuration in `terraform.tfvars`
- Modify `main.tf` to use data sources for your existing VPC
- See detailed instructions in `terraform.tfvars.example`

## Redis Cloud Features

This deployment includes:

- **Redis Enterprise**: Fully managed Redis with enterprise features
- **Redis Modules**: RedisJSON for JSON documents, RediSearch for full-text search
- **High Availability**: Multi-AZ deployment with replication
- **Persistence**: AOF (Append-Only File) every 1 second
- **Monitoring**: Built-in metrics and alerting via Redis Cloud console

## Outputs

Key outputs for connection and management:

- `vpc_id`: AWS VPC identifier
- `redis_cloud_connection_info`: Complete connection details (sensitive)
- `redis_cloud_cli_command`: Ready-to-use Redis CLI command (sensitive)
- `database_private_endpoint`: Private endpoint for VPC-internal connections
- `database_public_endpoint`: Public endpoint for external connections
- `rediscloud_subscription_id`: Redis Cloud subscription ID

## Cost Optimization

### Redis Cloud
- Start with smaller database sizes (1GB) and scale up as needed
- Use appropriate throughput settings (1000 ops/sec by default)
- Monitor usage in Redis Cloud console

### AWS Resources
- VPC and networking components have minimal cost
- No EC2 instances to manage = no compute costs
- Only pay for data transfer across VPC peering

## Security Best Practices

1. **Private Connectivity**: Redis traffic uses private VPC peering
2. **Network Isolation**: Redis Cloud in dedicated network (10.42.0.0/24)
3. **Encryption**: Redis Cloud provides encryption in transit and at rest
4. **Access Control**: Deploy applications in private subnets for security

## Use Cases

This configuration is ideal for:

- **Production Applications**: Secure Redis connectivity from your AWS applications
- **Microservices**: Shared Redis instance across multiple services in VPC
- **Development/Staging**: Cost-effective Redis Cloud testing environment
- **Migration Preparation**: Set up target Redis Cloud before data migration

## Troubleshooting

### Common Issues

1. **Redis Cloud subscription creation timeout**: 
   - Network connectivity issue with Redis Cloud API
   - Simply retry `terraform apply` - subscription may have been created successfully
   - Run `terraform refresh` to sync state with actual resources

2. **VPC Peering failed**: Check AWS account ID matches your actual account

3. **Can't connect to Redis Cloud**: Verify VPC peering status and routes

4. **Connection timeout**: Ensure your application is in private subnet

5. **Tag validation errors**: Redis Cloud requires lowercase tag keys (automatically handled)

### Useful Commands

```bash
# Check VPC peering status
aws ec2 describe-vpc-peering-connections

# Test connectivity from EC2 instance in private subnet
redis-cli -h REDIS_PRIVATE_IP -p PORT -a PASSWORD ping

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=VPC_ID"
```

## Monitoring

### Redis Cloud Console
- **URL**: https://app.redislabs.com
- **Features**: Built-in metrics, performance monitoring, alerting
- **Metrics**: Memory usage, operations/sec, latency, connections

### CloudWatch (AWS)
- VPC Flow Logs for network monitoring
- VPC peering connection status

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Note**: This will delete all AWS resources and the Redis Cloud subscription. The Redis Cloud subscription deletion may take a few minutes to complete.

## Modular Architecture

This project uses a modular Terraform architecture for production flexibility:

### **Modules Included:**
- **`modules/redis_subscription/`**: Manages Redis Cloud subscription, payment, and networking
- **`modules/redis_database/`**: Creates individual databases within a subscription  
- **`modules/vpc/`**: AWS VPC infrastructure with public/private subnets
- **`modules/rediscloud_peering/`**: VPC peering between AWS and Redis Cloud

### **Easy Scaling:**
```hcl
# Add more databases to existing subscription
module "redis_database_cache" {
  source = "./modules/redis_database"
  subscription_id = module.redis_subscription.subscription_id
  database_name = "cache-db"
  dataset_size_in_gb = 2
}

# Add additional subscriptions
module "redis_subscription_staging" {
  source = "./modules/redis_subscription"
  subscription_name = "staging-subscription"
  # ... configuration
}
```

## Next Steps

After deployment, you can:

1. **Deploy Applications**: Launch EC2 instances in private subnets
2. **Add More Databases**: Use the database module to create additional databases
3. **Add More Subscriptions**: Duplicate subscription modules for different environments
4. **Configure Monitoring**: Set up alerts in Redis Cloud console
5. **Scale Resources**: Increase database size and throughput as needed

## Support

- Redis Cloud Documentation: https://docs.redis.com/
- AWS VPC Documentation: https://docs.aws.amazon.com/vpc/
- Terraform Redis Cloud Provider: https://registry.terraform.io/providers/RedisLabs/rediscloud/