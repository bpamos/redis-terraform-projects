# Redis Cloud VPC Peering Module

Establishes VPC peering between Redis Cloud subscription and AWS VPC with comprehensive configuration options and robust validation.

## Features

- **🔗 Automated Peering**: Complete VPC peering setup between Redis Cloud and AWS
- **🛡️ Input Validation**: Comprehensive validation for AWS resource IDs and CIDR blocks
- **🔄 Flexible Routing**: Support for multiple route tables and optional route creation
- **⏱️ Configurable Timeouts**: Adjustable wait times and operation timeouts
- **🏷️ Resource Tagging**: Consistent tagging for AWS resources
- **📊 Detailed Outputs**: Comprehensive status and configuration information

## Usage

### Basic Configuration
```hcl
module "rediscloud_peering" {
  source = "./modules/rediscloud_peering"
  
  # Required parameters
  subscription_id  = module.rediscloud.rediscloud_subscription_id
  aws_account_id   = data.aws_caller_identity.current.account_id
  region           = var.aws_region
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = module.vpc.vpc_cidr_block
  route_table_id   = module.vpc.private_route_table_ids[0]
  peer_cidr_block  = "10.42.0.0/24"
}
```

### Advanced Configuration
```hcl
module "rediscloud_peering" {
  source = "./modules/rediscloud_peering"
  
  # Required parameters
  subscription_id  = module.rediscloud.rediscloud_subscription_id
  aws_account_id   = data.aws_caller_identity.current.account_id
  region           = var.aws_region
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = module.vpc.vpc_cidr_block
  route_table_id   = module.vpc.private_route_table_ids[0]
  peer_cidr_block  = "10.42.0.0/24"
  
  # Optional configuration
  name_prefix              = "myapp-redis"
  activation_wait_time     = 90
  peering_create_timeout   = "15m"
  peering_delete_timeout   = "15m"
  auto_accept_peering      = true
  create_route            = true
  additional_route_table_ids = toset([
    module.vpc.private_route_table_ids[1],
    module.vpc.public_route_table_id
  ])
  
  tags = {
    Environment = "production"
    Application = "redis-migration"
    Owner       = "platform-team"
  }
}
```

## Configuration Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `subscription_id` | string | **required** | Redis Cloud subscription ID |
| `aws_account_id` | string | **required** | AWS account ID (12 digits) |
| `region` | string | **required** | AWS region for VPC |
| `vpc_id` | string | **required** | AWS VPC ID (vpc-*) |
| `vpc_cidr` | string | **required** | VPC CIDR block |
| `route_table_id` | string | **required** | Primary route table ID (rtb-*) |
| `peer_cidr_block` | string | **required** | Redis Cloud network CIDR |
| `name_prefix` | string | `"redis-peering"` | Resource name prefix |
| `activation_wait_time` | number | `60` | Wait time for subscription (30-300s) |
| `peering_create_timeout` | string | `"10m"` | Peering creation timeout |
| `peering_delete_timeout` | string | `"10m"` | Peering deletion timeout |
| `auto_accept_peering` | bool | `true` | Auto-accept peering connection |
| `create_route` | bool | `true` | Create route in primary table |
| `additional_route_table_ids` | set(string) | `[]` | Additional route tables for routing |
| `tags` | map(string) | `{}` | Resource tags |

## Input Validation

The module includes comprehensive validation:

- **AWS Account ID**: Must be exactly 12 digits
- **VPC ID**: Must start with `vpc-`
- **Route Table IDs**: Must start with `rtb-`
- **CIDR Blocks**: Must be valid CIDR notation
- **Wait Time**: Must be between 30-300 seconds

## Resources Created

1. **null_resource.wait_for_subscription_activation**: Ensures Redis Cloud subscription is ready
2. **rediscloud_subscription_peering.peering**: Creates the peering connection
3. **aws_vpc_peering_connection_accepter.accepter**: Accepts the peering on AWS side
4. **aws_route.rediscloud_route**: Creates route in primary route table (optional)
5. **aws_route.rediscloud_routes_multiple**: Creates routes in additional tables

## Outputs

### Connection Information
- `peering_id`: Redis Cloud peering ID
- `aws_peering_id`: AWS peering connection ID
- `peering_status`: Connection status
- `aws_peering_connection_id`: Accepted connection ID

### Routing Information
- `primary_route_created`: Whether primary route was created
- `additional_routes_count`: Number of additional routes
- `route_destination_cidr`: Target CIDR block

### Configuration Summary
- `peering_config`: Complete configuration summary

## Process Flow

1. **⏱️ Wait for Activation**: Ensures Redis Cloud subscription is fully active
2. **🔗 Create Peering**: Establishes VPC peering connection
3. **✅ Accept Connection**: Automatically accepts peering on AWS side
4. **🛣️ Configure Routing**: Creates routes in specified route tables
5. **🏷️ Apply Tags**: Tags AWS resources consistently

## Requirements

- ✅ Redis Cloud subscription must be active and deployed
- ✅ AWS VPC must exist and be accessible
- ✅ Route tables must be created and accessible
- ✅ Proper IAM permissions for VPC peering operations
- ✅ Redis Cloud API credentials configured

## Important Notes

- **Timing**: Module waits for subscription activation before creating peering
- **Auto-Accept**: Peering connections are automatically accepted by default
- **Multiple Routes**: Supports routing to Redis Cloud from multiple route tables
- **Timeouts**: Configurable timeouts for long-running operations
- **Validation**: Extensive input validation prevents common configuration errors
- **Idempotent**: Safe to run multiple times without side effects