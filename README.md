# Redis Terraform Projects

This repository contains a collection of standalone Terraform projects for deploying various Redis infrastructure configurations on AWS. Each project is designed to be independently deployable and serves different use cases in Redis migration and testing scenarios.

## Project Structure

```
redis-terraform-projects/
├── README.md                           # This file
│
├── redis-cloud/                        # Redis Cloud Deployments
│   ├── redis-cloud-simple/             # Redis Cloud + VPC (no modules, basic, hardcoded)
│   ├── redis-cloud-basic/              # Basic Redis Cloud deployment
│   ├── redis-cloud-migration-demo/     # Complete migration workflow with cutover UI
│   ├── redis-cloud-plus-aws-vpc-peering/         # Redis Cloud VPC peering
│   ├── redis-cloud-plus-aws-vpc-with-ec2/        # Redis Cloud with VPC peering and EC2
│   └── redis-cloud-riot/               # Redis Cloud + RIOT migration tools
│
├── redis-enterprise-software/          # Redis Enterprise Software Deployments
│   ├── redis-enterprise-software-aws/  # Redis Enterprise with Route53 DNS
│   ├── redis-enterprise-software-aws-eks/        # Redis Enterprise on EKS
│   └── redis-enterprise-software-aws-lb/         # Redis Enterprise with Load Balancers
│
└── other-infra/                        # Supporting Infrastructure
    ├── elasticache-only/               # AWS ElastiCache Redis deployment
    ├── riot-tooling-only/              # RIOT tools with local Redis OSS
    └── vpc-only/                       # Standalone VPC infrastructure
```

## Projects Overview

## Redis Cloud Projects

### redis-cloud-simple
**Location**: `redis-cloud/redis-cloud-simple/`

**The Simplest Redis Cloud Setup** - Learn Redis Cloud + AWS in minutes:
- **4 files total** - No modules, everything in plain sight
- **Hardcoded values** - Sensible defaults, just add credentials
- **<300 lines** of Terraform code
- **Perfect for**: Learning, PoC, understanding the basics
- **Deploy time**: <5 minutes
- Redis Cloud 1GB database + AWS VPC + VPC peering
- See full version: `redis-cloud/redis-cloud-plus-aws-vpc-with-ec2`

### 🚀 redis-cloud-migration-demo
**Location**: `redis-cloud/redis-cloud-migration-demo/`

**Complete Redis Cloud migration workflow** - End-to-end migration infrastructure including:
- AWS VPC with public/private subnets
- Redis Cloud subscription and database
- AWS ElastiCache Redis cluster
- RIOT EC2 instance for migration tools
- VPC peering between AWS and Redis Cloud
- Comprehensive monitoring and observability
- Cutover management UI

### ☁️ redis-cloud-plus-aws-vpc-with-ec2
**Location**: `redis-cloud/redis-cloud-plus-aws-vpc-with-ec2/`

**Redis Cloud with VPC Peering and EC2** - Complete Redis Cloud setup:
- Redis Cloud subscription and database
- AWS VPC with EC2 instances
- VPC peering for private connectivity
- Security groups and networking
- Optional Prometheus/Grafana monitoring
- Great for hybrid cloud architectures

### 🌐 redis-cloud-plus-aws-vpc-peering
**Location**: `redis-cloud/redis-cloud-plus-aws-vpc-peering/`

**Redis Cloud VPC Peering** - Simplified VPC peering setup:
- Redis Cloud subscription
- AWS VPC peering configuration
- Minimal setup for network connectivity
- Foundation for private Redis Cloud access

### ☁️ redis-cloud-basic
**Location**: `redis-cloud/redis-cloud-basic/`

**Basic Redis Cloud** - Minimal Redis Cloud deployment:
- Redis Cloud subscription and database
- Basic networking configuration
- Ideal for testing Redis Cloud features in isolation

### 🔧 redis-cloud-riot
**Location**: `redis-cloud/redis-cloud-riot/`

**Redis Cloud + Migration Tools** - Redis Cloud with RIOT tooling:
- Redis Cloud subscription and database
- AWS VPC and networking
- RIOT EC2 instance with migration tools
- VPC peering for private connectivity
- Perfect for Redis Cloud migration projects

## Redis Enterprise Software Projects

### 🏢 redis-enterprise-software-aws
**Location**: `redis-enterprise-software/redis-enterprise-software-aws/`

**Redis Enterprise Software with DNS** - Production-ready Redis Enterprise cluster:
- Multi-platform support (Ubuntu 22.04 or RHEL 9)
- 3-node HA cluster with rack awareness across AZs
- Automated Route53 DNS records
- EBS volume persistence with proper ownership
- Comprehensive cluster health validation
- VPC isolation with security groups
- Perfect for production Redis Enterprise deployments

### ⚖️ redis-enterprise-software-aws-lb
**Location**: `redis-enterprise-software/redis-enterprise-software-aws-lb/`

**Redis Enterprise Software with Load Balancers** - Redis Enterprise with multiple LB options:
- Choice of AWS Network Load Balancer (NLB), NGINX, or HAProxy
- Multi-platform support (Ubuntu 22.04 or RHEL 9)
- 3-node HA cluster with rack awareness
- EBS volume persistence with proper ownership
- Advanced NGINX configurations (port mapping, health checks, load balancing methods)
- Ideal for production deployments requiring custom load balancing

### 📦 redis-enterprise-software-aws-eks
**Location**: `redis-enterprise-software/redis-enterprise-software-aws-eks/`

**Redis Enterprise Software on EKS** - Redis Enterprise deployed on Amazon EKS:
- Kubernetes-based deployment
- EKS cluster with Redis Enterprise operator
- Container-native architecture
- Ideal for cloud-native applications

## Supporting Infrastructure Projects

### 🛠️ riot-tooling-only
**Location**: `other-infra/riot-tooling-only/`

**RIOT Tools + Local Redis** - Migration tooling environment:
- AWS VPC and EC2 infrastructure
- RIOT-X migration tools
- Local Redis OSS instance
- Prometheus and Grafana monitoring
- Great for testing migration scripts and tooling

### 🏗️ elasticache-only
**Location**: `other-infra/elasticache-only/`

**AWS ElastiCache** - AWS-native Redis deployment:
- AWS VPC with subnets
- ElastiCache Redis cluster
- Security groups and networking
- Ideal for AWS-native Redis testing

### 🌐 vpc-only
**Location**: `other-infra/vpc-only/`

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
- Route53 hosted zone (for Redis Enterprise DNS project)
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

### Production Deployments
- **Redis Enterprise Software with DNS**: `redis-enterprise-software-aws`
  - Production-ready cluster with Route53 DNS
  - Automatic failover and HA across availability zones
  - Ubuntu 22.04 or RHEL 9 platform options

- **Redis Enterprise Software with Load Balancers**: `redis-enterprise-software-aws-lb`
  - Choose NLB (managed), NGINX, or HAProxy
  - Advanced load balancing configurations
  - Custom port mapping and health checks

- **Redis Cloud with VPC Peering**: `redis-cloud-plus-aws-vpc-with-ec2`
  - Hybrid cloud architecture
  - Private connectivity between AWS and Redis Cloud
  - EC2 application integration

### Migration Scenarios
- **Source: On-premises Redis → Target: Redis Cloud**
  Use: `redis-cloud-riot` for migration pipeline

- **Source: AWS ElastiCache → Target: Redis Cloud**
  Use: `redis-cloud-migration-demo` for complete workflow with UI

- **Source: Any Redis → Target: ElastiCache**
  Use: `elasticache-only` + `riot-tooling-only`

### Security & Compliance
- **Enhanced Security**: `redis-cloud-plus-aws-vpc-with-ec2-security`
- **RBAC and ACLs**: `redis-cloud-plus-aws-vpc-with-ec2-roles-acls`
- **Private Connectivity**: `redis-cloud-plus-aws-vpc-peering`

### Testing & Development
- **Redis Cloud feature testing**: `redis-cloud-basic`
- **Redis Enterprise testing**: `redis-enterprise-software-aws`
- **AWS ElastiCache testing**: `elasticache-only`
- **Migration script development**: `riot-tooling-only`
- **Network connectivity testing**: `vpc-only`

## Key Features

### 🏢 Redis Enterprise Software
- Multi-platform support (Ubuntu 22.04, RHEL 9)
- High availability with rack awareness across AZs
- EBS volume persistence with proper ownership configuration
- Automated Route53 DNS records or Load Balancer options
- Choice of NLB (AWS managed), NGINX, or HAProxy
- Comprehensive cluster health validation
- Production-ready configurations

### 🔐 Security
- All sensitive values in gitignored `terraform.tfvars`
- Security groups with minimal required access
- VPC peering for private connectivity
- SSH key-based authentication
- EBS encryption enabled
- RBAC and ACL support (Redis Cloud projects)

### 📊 Monitoring
- Prometheus metrics collection
- Grafana dashboards (where applicable)
- CloudWatch integration
- RIOT-X built-in monitoring
- Redis Enterprise cluster status validation

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
- Multi-platform support with conditional logic

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

## Available Projects

| Project | Location | Type | Key Features |
|---------|----------|------|--------------|
| **redis-cloud-simple** ⭐ | `redis-cloud/` | **Learning** | **Simplest setup - 4 files, no modules, <300 lines** |
| redis-cloud-migration-demo | `redis-cloud/` | Migration | Complete migration workflow with cutover UI |
| redis-cloud-plus-aws-vpc-with-ec2 | `redis-cloud/` | Cloud | Redis Cloud with VPC peering and EC2 |
| redis-cloud-plus-aws-vpc-peering | `redis-cloud/` | Cloud | Simplified VPC peering setup |
| redis-cloud-basic | `redis-cloud/` | Cloud | Minimal Redis Cloud deployment |
| redis-cloud-riot | `redis-cloud/` | Migration | Redis Cloud + RIOT migration tools |
| redis-enterprise-software-aws | `redis-enterprise-software/` | Enterprise | Redis Enterprise with Route53 DNS, multi-AZ HA |
| redis-enterprise-software-aws-lb | `redis-enterprise-software/` | Enterprise | Redis Enterprise with NLB/NGINX/HAProxy options |
| redis-enterprise-software-aws-eks | `redis-enterprise-software/` | Enterprise | Redis Enterprise on Amazon EKS |
| riot-tooling-only | `other-infra/` | Tooling | RIOT tools + local Redis OSS + monitoring |
| elasticache-only | `other-infra/` | AWS Native | AWS ElastiCache deployment |
| vpc-only | `other-infra/` | Networking | Standalone VPC infrastructure |

## Contributing

When adding new projects or modifications:
1. Follow existing naming conventions
2. Include comprehensive variable validation
3. Add appropriate outputs for key resource information
4. Update this README with project descriptions
5. Test all configurations before committing

---

**Note**: All projects are configured with real credentials in `terraform.tfvars` files. These files are gitignored for security. Each project can be deployed independently based on your specific use case.