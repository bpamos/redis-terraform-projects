# Redis Terraform Projects

This repository contains a collection of standalone Terraform projects for deploying various Redis infrastructure configurations on AWS. Each project is designed to be independently deployable and serves different use cases in Redis migration and testing scenarios.

## Project Structure

```
redis-terraform-projects/
├── README.md                           # This file
├── redis-cloud-migration-demo/         # Main reference implementation
├── elasticache-only/                   # AWS ElastiCache Redis deployment
├── redis-cloud-only/                   # Redis Cloud standalone deployment
├── redis-cloud-riot/                   # Redis Cloud + RIOT migration tools
├── riot-tooling-only/                  # RIOT tools with local Redis OSS
└── vpc-only/                           # Standalone VPC infrastructure
```

## Projects Overview

### 🚀 redis-cloud-migration-demo
**Main reference implementation** - Complete Redis migration infrastructure including:
- AWS VPC with public/private subnets
- Redis Cloud subscription and database
- AWS ElastiCache Redis cluster
- RIOT EC2 instance for migration tools
- VPC peering between AWS and Redis Cloud
- Comprehensive monitoring and observability
- Cutover management UI

### ☁️ redis-cloud-only
**Redis Cloud standalone** - Minimal Redis Cloud deployment:
- Redis Cloud subscription and database
- Basic networking configuration
- Ideal for testing Redis Cloud features in isolation

### 🔧 redis-cloud-riot
**Redis Cloud + Migration Tools** - Redis Cloud with RIOT tooling:
- Redis Cloud subscription and database
- AWS VPC and networking
- RIOT EC2 instance with migration tools
- VPC peering for private connectivity
- Perfect for Redis Cloud migration projects

### 🛠️ riot-tooling-only
**RIOT Tools + Local Redis** - Migration tooling environment:
- AWS VPC and EC2 infrastructure
- RIOT-X migration tools
- Local Redis OSS instance
- Prometheus and Grafana monitoring
- Great for testing migration scripts and tooling

### 🏗️ elasticache-only
**AWS ElastiCache** - AWS-native Redis deployment:
- AWS VPC with subnets
- ElastiCache Redis cluster
- Security groups and networking
- Ideal for AWS-native Redis testing

### 🌐 vpc-only
**VPC Infrastructure** - Reusable networking foundation:
- AWS VPC with public/private subnets
- Internet Gateway and route tables
- Security groups
- Foundation for other projects

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Redis Cloud account (for Redis Cloud projects)
- SSH key pair in AWS (specified in terraform.tfvars)

### Quick Start
1. Navigate to any project directory
2. Review and update `terraform.tfvars` with your specific values
3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Configuration Files
Each project includes:
- `terraform.tfvars` - Pre-configured with your credentials and settings
- `variables.tf` - Variable definitions and validation
- `main.tf` - Infrastructure resources
- `outputs.tf` - Useful output values
- `versions.tf` - Provider version constraints

## Use Cases

### Migration Scenarios
- **Source: On-premises Redis → Target: Redis Cloud**
  Use: `redis-cloud-riot` for complete migration pipeline

- **Source: AWS ElastiCache → Target: Redis Cloud**  
  Use: `redis-cloud-migration-demo` for full environment

- **Source: Any Redis → Target: ElastiCache**
  Use: `elasticache-only` + `riot-tooling-only`

### Testing & Development
- **Redis Cloud feature testing**: `redis-cloud-only`
- **AWS ElastiCache testing**: `elasticache-only`
- **Migration script development**: `riot-tooling-only`
- **Network connectivity testing**: `vpc-only`

## Key Features

### 🔐 Security
- All sensitive values in gitignored `terraform.tfvars`
- Security groups with minimal required access
- VPC peering for private connectivity
- SSH key-based authentication

### 📊 Monitoring
- Prometheus metrics collection
- Grafana dashboards (where applicable)
- CloudWatch integration
- RIOT-X built-in monitoring

### 🚀 Migration Tools
- RIOT-X for data migration and synchronization
- Redis CLI tools and utilities
- Connection validation scripts
- Performance testing capabilities
- Web-based cutover management UI

### 🏗️ Infrastructure as Code
- Modular Terraform design
- Reusable modules across projects
- Consistent naming and tagging
- Validation and error handling

## Project Dependencies

### AWS Resources
- VPC, subnets, and networking components
- EC2 instances and security groups
- ElastiCache clusters (where applicable)
- Route tables and internet gateways

### Redis Cloud Resources
- Subscriptions and databases
- VPC peering connections
- Payment method configuration
- Regional deployments

## Support and Troubleshooting

### Common Issues
1. **Provider authentication**: Ensure AWS and Redis Cloud credentials are configured
2. **Resource limits**: Check AWS service quotas and Redis Cloud subscription limits
3. **Network connectivity**: Verify VPC peering and security group configurations
4. **SSH access**: Confirm key pair exists and paths are correct

### Useful Commands
```bash
# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply infrastructure
terraform apply

# Destroy resources
terraform destroy

# Format code
terraform fmt -recursive
```

## Architecture Patterns

Each project follows consistent patterns:
- **Networking**: VPC with public/private subnet separation
- **Security**: Least-privilege security groups
- **Monitoring**: Observability stack where applicable  
- **Naming**: Consistent resource naming with prefixes
- **Tagging**: Standard tags for resource management

## Project Status

All projects are fully configured and ready to deploy:

| Project | Status | Features |
|---------|--------|----------|
| redis-cloud-migration-demo | ✅ Ready | Full migration pipeline with UI |
| redis-cloud-only | ✅ Ready | Minimal Redis Cloud deployment |
| redis-cloud-riot | ✅ Ready | Redis Cloud + RIOT tools |
| riot-tooling-only | ✅ Ready | RIOT tools + local Redis OSS |
| elasticache-only | ✅ Ready | AWS ElastiCache deployment |
| vpc-only | ✅ Ready | Standalone VPC infrastructure |

## Contributing

When adding new projects or modifications:
1. Follow existing naming conventions
2. Include comprehensive variable validation
3. Add appropriate outputs for key resource information
4. Update this README with project descriptions
5. Test all configurations before committing

---

**Note**: All projects are configured with real credentials in `terraform.tfvars` files. These files are gitignored for security. Each project can be deployed independently based on your specific use case.