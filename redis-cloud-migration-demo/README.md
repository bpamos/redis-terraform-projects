# Redis Cloud Migration Demo

A comprehensive Terraform-based solution for migrating data from **AWS ElastiCache Redis** to **Redis Cloud** using **RIOT-X** with automated infrastructure provisioning and migration tools.

## 🚀 What This Deploys

This fully automated setup provisions:

- ✅ **AWS VPC Infrastructure** - Custom VPC, subnets, security groups, and Internet Gateway
- ✅ **ElastiCache Redis** - Standalone Redis with keyspace notifications enabled  
- ✅ **Redis Cloud** - Subscription, database, and VPC peering with AWS
- ✅ **RIOT EC2 Instance** - Pre-configured with Redis OSS, RIOT-X, and observability tools
- ✅ **Application EC2** - Flask demo app and cutover management UI
- ✅ **RIOT-X Replication** - Automated live replication from ElastiCache to Redis Cloud
- ✅ **Monitoring & Demo Tools** - Memtier benchmark, cutover utilities, and management interfaces

## 🔧 Prerequisites

- [Terraform](https://www.terraform.io/downloads) (>= 1.3.0)
- AWS credentials configured (via environment variables or AWS config)
- Redis Cloud account with API credentials
- SSH key pair in your target AWS region

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Navigate to this project directory
cd redis-cloud-migration-demo

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
```

### 2. Update Configuration

Edit `terraform.tfvars` with your specific values:

```hcl
#==============================================================================  
# REQUIRED USER CONFIGURATION
#==============================================================================

# Project identification - CHANGE THESE VALUES
name_prefix = "your-project-name"  # Must be unique and lowercase
owner       = "your-name"          # Your name or team

# AWS infrastructure - CHANGE THESE VALUES  
key_name             = "your-ec2-keypair"        # Your EC2 key pair name
ssh_private_key_path = "~/path/to/your-key.pem"  # Path to your SSH private key
aws_account_id       = "123456789012"            # Your 12-digit AWS account ID

# Redis Cloud credentials - CHANGE THESE VALUES
rediscloud_api_key       = "your-api-key"
rediscloud_secret_key    = "your-secret-key"
credit_card_last_four    = "1234"               # Last 4 digits of your card

# Network security - CHANGE THIS VALUE
allow_ssh_from = ["203.0.113.0/24"]  # Your IP range for SSH access
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy everything
terraform apply
```

## 📊 Infrastructure Components

| Component | Description | Purpose |
|----------|-------------|---------|
| **VPC & Networking** | Custom VPC with public/private subnets | Isolated network environment |
| **Security Groups** | Granular access controls | Secure communication between components |
| **ElastiCache Redis** | Source Redis database | Data source for migration |
| **Redis Cloud** | Target Redis database | Migration destination |
| **VPC Peering** | Secure connection between AWS and Redis Cloud | Private network connectivity |
| **RIOT EC2** | RIOT-X migration server | Data replication and tooling |
| **Application EC2** | Demo application server | Sample workload and management UI |
| **RIOT-X Replication** | Automated data sync | Live replication from source to target |

## 🔄 Migration Process

The infrastructure automatically sets up **live replication** from ElastiCache to Redis Cloud:

1. **Infrastructure Deployment** - All AWS and Redis Cloud resources are created
2. **VPC Peering** - Secure private connectivity is established
3. **RIOT-X Setup** - Migration tools are installed and configured
4. **Live Replication** - Data sync begins automatically
5. **Monitoring** - Observe replication progress via web interfaces

### Access Your Deployment

After deployment, Terraform outputs provide access information:

```bash
# View all connection details
terraform output

# Key endpoints:
# - Application URL: http://<application-ip>:5000
# - Cutover UI: http://<application-ip>:8080  
# - Grafana: http://<riot-ip>:3000
# - Prometheus: http://<riot-ip>:9090
```

## 🛠️ Management & Monitoring

### Web Interfaces

- **Application Demo**: Flask app showcasing Redis connectivity
- **Cutover Management**: Web UI for switching between data sources
- **Grafana Dashboards**: Visual monitoring of replication metrics
- **Prometheus Metrics**: Detailed RIOT-X performance data

### SSH Access

```bash
# Access RIOT server
ssh -i /path/to/your-key.pem ubuntu@<riot-ip>

# Check RIOT-X status
sudo systemctl status riotx
tail -f /home/ubuntu/riotx.log

# Access application server  
ssh -i /path/to/your-key.pem ubuntu@<app-ip>
```

### Replication Monitoring

```bash
# View live replication logs
ssh ubuntu@<riot-ip> 'tail -f /home/ubuntu/riotx.log'

# Check replication metrics
curl http://<riot-ip>:8080/metrics
```

## 🎯 Cutover Process

When ready to switch from ElastiCache to Redis Cloud:

1. **Verify Replication**: Ensure data sync is complete and current
2. **Stop Application Traffic**: Temporarily halt writes to ElastiCache  
3. **Final Sync**: Allow final data replication to complete
4. **Switch Configuration**: Use cutover UI or update application config
5. **Resume Traffic**: Direct application to Redis Cloud
6. **Monitor**: Verify application functionality with new data source

## 🔐 Security Features

- **Network Isolation**: Private subnets for databases
- **Security Groups**: Granular port and protocol controls
- **VPC Peering**: Secure private connectivity
- **SSH Access Control**: Configurable IP restrictions
- **Sensitive Data**: API keys marked as sensitive in Terraform

## 💰 Cost Optimization

- **ElastiCache**: Uses cost-effective t3.micro instances
- **EC2 Instances**: Right-sized for workload requirements
- **Redis Cloud**: Minimal configuration for demonstration
- **VPC Peering**: No data transfer charges within same region

## 🧹 Cleanup

To destroy all provisioned infrastructure:

```bash
terraform destroy
```

**Note**: This will permanently delete all resources including data. Ensure you have backups if needed.

## 📁 Project Structure

```
redis-cloud-migration-demo/
├── main.tf                    # Root Terraform configuration
├── variables.tf               # Input variables with validation
├── outputs.tf                 # Output values  
├── terraform.tfvars.example   # Configuration template
├── provider.tf                # AWS and Redis Cloud providers
├── versions.tf                # Terraform and provider versions
└── modules/                   # Modular components
    ├── vpc/                   # VPC and networking
    ├── security_group/        # Security group rules
    ├── elasticache/           # ElastiCache Redis
    ├── rediscloud/           # Redis Cloud subscription
    ├── rediscloud_peering/    # VPC peering setup
    ├── ec2_riot/             # RIOT-X server
    ├── ec2_application/       # Application server
    ├── riotx_replication/     # Replication automation
    ├── cutover/              # Cutover scripts
    ├── cutover_ui/           # Cutover management UI
    └── scripts/              # Utility scripts
```

## 🔧 Customization

The deployment is highly configurable through variables:

- **Network Configuration**: VPC CIDRs, subnet layouts, security rules
- **Instance Sizing**: EC2 and ElastiCache instance types
- **Redis Configuration**: Versions, modules, persistence settings
- **Monitoring**: Enable/disable observability components
- **Security**: SSH access restrictions, encryption settings

See `variables.tf` for complete configuration options.

## 📚 Additional Resources

- [RIOT-X Documentation](https://github.com/redis-field-engineering/riotx-dist)
- [Redis Cloud Documentation](https://docs.redis.com/latest/rc/)
- [AWS ElastiCache Documentation](https://docs.aws.amazon.com/elasticache/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ⚠️ Important Notes

- **Production Use**: Review security settings before production deployment
- **Data Safety**: Always test migration process with non-critical data first
- **Monitoring**: Monitor replication lag and application performance during migration
- **Backup**: Ensure proper backups exist before starting migration process
- **Costs**: Be aware of AWS and Redis Cloud usage charges