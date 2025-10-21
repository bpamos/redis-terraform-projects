# Security Groups Module

Creates and manages security groups for Redis migration infrastructure with comprehensive access controls and configurable security policies.

## Features

- **🛡️ Comprehensive Security**: Three specialized security groups for different components
- **🔧 Configurable Access**: Fine-grained control over port access and CIDR blocks
- **📊 Observability Support**: Built-in support for monitoring tools (Grafana, Prometheus)
- **🔍 Input Validation**: Validates CIDR blocks, ports, and security group IDs
- **🏷️ Flexible Tagging**: Support for both modern tags variable and legacy tag variables
- **🔄 Dynamic Rules**: Uses dynamic blocks for conditional rule creation

## Security Groups Created

### 1. RIOT EC2 Security Group
- **Purpose**: Secures RIOT EC2 instances with Redis OSS and observability tools
- **Ports**: SSH (22), Grafana (3000), Prometheus (9090), RIOT-X metrics (configurable)
- **Features**: Optional Redis OSS access for testing

### 2. ElastiCache Security Group  
- **Purpose**: Secures ElastiCache Redis clusters
- **Ports**: Redis (6379) from authorized security groups only
- **Features**: Support for additional security group access

### 3. Application EC2 Security Group
- **Purpose**: Secures application EC2 instances (Flask app, cutover UI)
- **Ports**: SSH (22), Flask app (configurable), Cutover UI (configurable), custom ports
- **Features**: Flexible custom port configuration

## Usage

### Basic Configuration
```hcl
module "security_groups" {
  source = "./modules/security_group"
  
  name_prefix = "redis-migration"
  vpc_id      = module.vpc.vpc_id
  
  # Restrict SSH access to your network
  ssh_cidr_blocks = ["203.0.113.0/24"]
  
  tags = {
    Environment = "production"
    Project     = "redis-migration"
    Owner       = "platform-team"
  }
}
```

### Advanced Security Configuration
```hcl
module "security_groups" {
  source = "./modules/security_group"
  
  name_prefix = "secure-redis"
  vpc_id      = module.vpc.vpc_id
  
  # SSH access control
  enable_ssh_access = true
  ssh_cidr_blocks   = ["10.0.0.0/8", "203.0.113.0/24"]
  
  # Observability access control
  enable_observability_access = true
  observability_cidr_blocks   = ["10.0.0.0/8"]
  
  # RIOT-X metrics configuration
  enable_riotx_metrics = true
  riotx_metrics_port   = 9000
  metrics_cidr_blocks  = ["10.0.0.0/8"]
  
  # Application access control
  enable_flask_access      = true
  flask_port              = 5000
  enable_cutover_ui_access = true
  cutover_ui_port         = 8080
  application_cidr_blocks = ["10.0.0.0/8"]
  
  # Custom application ports
  custom_application_ports = [
    {
      port        = 9001
      description = "Custom monitoring endpoint"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
  
  # Additional Redis access
  additional_redis_security_groups = toset([
    "sg-0123456789abcdef0"  # Lambda security group
  ])
  
  # Disable insecure access
  enable_redis_oss_access = false
  
  tags = {
    Environment = "production"
    Project     = "redis-migration"
    Owner       = "platform-team"
    Compliance  = "SOC2"
  }
}
```

### High-Security Configuration
```hcl
module "security_groups" {
  source = "./modules/security_group"
  
  name_prefix = "secure-redis"
  vpc_id      = module.vpc.vpc_id
  
  # Restrict access to internal networks only
  ssh_cidr_blocks           = ["10.0.0.0/16"]
  observability_cidr_blocks = ["10.0.1.0/24"]  # Monitoring subnet only
  application_cidr_blocks   = ["10.0.2.0/24"]  # App subnet only
  metrics_cidr_blocks       = ["10.0.1.0/24"]  # Monitoring subnet only
  
  # Disable external Redis OSS access
  enable_redis_oss_access = false
  
  # Custom secure ports
  riotx_metrics_port = 9443
  flask_port        = 8443
  cutover_ui_port   = 9443
  
  tags = {
    Environment   = "production"
    SecurityLevel = "high"
    Compliance    = "PCI-DSS"
  }
}
```

## Configuration Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name_prefix` | string | **required** | Prefix for security group names |
| `vpc_id` | string | **required** | VPC ID where SGs will be created |
| `enable_ssh_access` | bool | `true` | Enable SSH access to EC2 instances |
| `ssh_cidr_blocks` | list(string) | `["0.0.0.0/0"]` | CIDR blocks for SSH access |
| `enable_observability_access` | bool | `true` | Enable observability tools access |
| `observability_cidr_blocks` | list(string) | `["0.0.0.0/0"]` | CIDR blocks for monitoring tools |
| `enable_riotx_metrics` | bool | `true` | Enable RIOT-X metrics endpoint |
| `riotx_metrics_port` | number | `8080` | Port for RIOT-X metrics |
| `metrics_cidr_blocks` | list(string) | `["0.0.0.0/0"]` | CIDR blocks for metrics access |
| `enable_redis_oss_access` | bool | `false` | Enable external Redis OSS access |
| `redis_oss_cidr_blocks` | list(string) | `[]` | CIDR blocks for Redis OSS access |
| `enable_flask_access` | bool | `true` | Enable Flask application access |
| `flask_port` | number | `5000` | Port for Flask application |
| `enable_cutover_ui_access` | bool | `true` | Enable cutover UI access |
| `cutover_ui_port` | number | `8080` | Port for cutover UI |
| `application_cidr_blocks` | list(string) | `["0.0.0.0/0"]` | CIDR blocks for app access |
| `custom_application_ports` | list(object) | `[]` | Custom application ports to open |
| `additional_redis_security_groups` | set(string) | `[]` | Additional SGs for Redis access |
| `tags` | map(string) | `{}` | Tags to apply to all resources |

## Input Validation

The module includes comprehensive validation:

- **VPC ID**: Must start with `vpc-`
- **CIDR Blocks**: All CIDR blocks validated using `cidrhost()` function
- **Ports**: All ports must be between 1-65535
- **Security Group IDs**: Must start with `sg-`

## Security Best Practices

### ✅ Recommended Practices
- **Restrict SSH Access**: Use specific CIDR blocks instead of `0.0.0.0/0`
- **Separate Network Segments**: Use different CIDR blocks for different access types
- **Disable Unused Services**: Set `enable_redis_oss_access = false` in production
- **Custom Ports**: Use non-standard ports for additional security
- **Monitor Access**: Enable observability tools with restricted access

### ❌ Security Anti-patterns
- Using `0.0.0.0/0` for SSH access in production
- Enabling Redis OSS external access in production
- Using default ports for all services
- Granting broad access to observability tools

## Outputs

### Security Group IDs
- `riot_ec2_sg_id`: RIOT EC2 security group ID
- `elasticache_sg_id`: ElastiCache security group ID  
- `ec2_application_sg_id`: Application EC2 security group ID

### Security Group ARNs
- `riot_ec2_sg_arn`: RIOT EC2 security group ARN
- `elasticache_sg_arn`: ElastiCache security group ARN
- `ec2_application_sg_arn`: Application EC2 security group ARN

### Configuration Status
- `ssh_access_enabled`: SSH access status
- `observability_access_enabled`: Observability access status
- `riotx_metrics_enabled`: RIOT-X metrics status
- `redis_oss_access_enabled`: Redis OSS access status

### Summary Information
- `application_ports`: Summary of configured ports
- `security_groups_summary`: Complete configuration summary

## Important Notes

- **Default Behavior**: SSH and application access default to `0.0.0.0/0` - restrict in production
- **Redis OSS Access**: Disabled by default for security - only enable for testing
- **Dynamic Rules**: Rules are created conditionally based on enable flags
- **Legacy Support**: Maintains backward compatibility with `owner` and `project` variables
- **ElastiCache Security**: Only allows Redis access from specific security groups
- **Egress Rules**: All security groups allow unrestricted outbound traffic