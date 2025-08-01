# Simple VPC Module

Creates a basic AWS VPC with public and private subnets, perfect for VPC peering and simple networking setups.

## What It Creates

- **VPC** with DNS support and hostnames enabled
- **Internet Gateway** for public subnet connectivity  
- **Public Subnets** across multiple AZs with auto-assigned public IPs
- **Private Subnets** across multiple AZs (no internet access)
- **Route Tables** - one for public subnets, one for private subnets
- **Routes** - public subnets route to Internet Gateway

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix = "redis-migration"
  vpc_cidr    = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  azs                  = ["us-west-2a", "us-west-2b"]
  
  tags = {
    Environment = "production"
    Project     = "redis-migration"
  }
}
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name_prefix` | string | **required** | Prefix for resource names |
| `vpc_cidr` | string | `"10.0.0.0/16"` | VPC CIDR block |
| `public_subnet_cidrs` | list(string) | **required** | Public subnet CIDR blocks |
| `private_subnet_cidrs` | list(string) | **required** | Private subnet CIDR blocks |
| `azs` | list(string) | **required** | Availability zones |
| `tags` | map(string) | `{}` | Tags for all resources |

## Outputs

- `vpc_id` - VPC ID for peering
- `vpc_cidr_block` - VPC CIDR block
- `public_subnet_ids` - Public subnet IDs  
- `private_subnet_ids` - Private subnet IDs
- `public_route_table_id` - Public route table ID
- `private_route_table_ids` - Private route table IDs (list with one ID)

## Perfect For

- **VPC Peering** - Simple structure makes peering easy
- **Redis Migration** - Public subnets for RIOT EC2, private for databases
- **Basic Networking** - No complex NAT gateways or endpoints
- **Cost Optimization** - Only creates essential resources

## Route Table Access

The module exposes route table IDs so you can easily add routes for:
- VPC peering connections
- VPN connections  
- Other custom routing needs

Private subnets have no internet access by default - perfect for databases and internal services.