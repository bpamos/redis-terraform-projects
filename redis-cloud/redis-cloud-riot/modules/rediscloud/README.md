# Redis Cloud Module

Creates a Redis Cloud subscription and database with VPC networking, comprehensive validation, and monitoring alerts.

## Features

- **🔐 Secure Configuration**: Input validation for all critical parameters
- **📊 Enhanced Monitoring**: Built-in alerts for dataset size and throughput
- **⚙️ Flexible Options**: Configurable modules, persistence, and maintenance windows
- **🌐 VPC Networking**: Private connectivity support for AWS environments

## Resources Created

- Redis Cloud subscription with AWS integration
- Redis Cloud database with specified configuration and modules
- VPC networking deployment for private connectivity
- Monitoring alerts for proactive issue detection

## Usage

```hcl
module "rediscloud" {
  source = "./modules/rediscloud"
  
  rediscloud_api_key         = var.rediscloud_api_key
  rediscloud_secret_key      = var.rediscloud_secret_key
  subscription_name          = "redis-demo-subscription"
  rediscloud_region          = "us-west-2"
  cloud_provider             = "AWS"
  networking_deployment_cidr = "10.42.0.0/24"
  memory_storage             = "ram"
  dataset_size_in_gb         = 1
  throughput_value           = 1000
  modules                    = ["RedisJSON"]
}
```

## Configuration Validation

The module includes comprehensive input validation:
- **Maintenance Windows**: Hours (0-23), duration (1-24h), valid day names
- **Persistence Modes**: Only valid Redis persistence options allowed
- **Redis Modules**: Validates against supported Redis Enterprise modules
- **Throughput**: Positive values required for dataset size and throughput
- **Cloud Provider**: AWS-only deployment (no GCP support)

## Monitoring & Alerts

Automatically configured alerts:
- **Dataset Size**: Alert when usage exceeds 95%
- **Throughput**: Alert when throughput exceeds 80% of configured capacity

## Important Notes

- Requires Redis Cloud API credentials
- VPC networking enables private connectivity to AWS
- Database password is auto-generated and marked as sensitive
- Only AWS cloud provider is supported
- Credit card payment method required

## Outputs

- `rediscloud_subscription_id` - The subscription ID
- `database_private_endpoint` - Private endpoint for database access
- `rediscloud_password` - Database password (sensitive)