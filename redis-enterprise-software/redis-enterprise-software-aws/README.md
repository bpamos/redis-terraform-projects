# Redis Enterprise Software on AWS - Simplified Deployment

Deploy a production-ready Redis Enterprise Software cluster on AWS with automated DNS, multi-platform support, and comprehensive validation.

## 🚀 Quick Start

### 1. Prerequisites
- **AWS Account** with credentials configured (`aws configure`)
- **Terraform** >= 1.0
- **Route53 Hosted Zone** for DNS records
- **EC2 Key Pair** in your target region

### 2. Deploy in 3 Steps

```bash
# 1. Clone and configure
git clone <repository-url>
cd redis-enterprise-software-aws2
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars (see Configuration section)
# Required: user_prefix, aws_region, key_name, ssh_private_key_path, 
#           dns_hosted_zone_id, re_download_url, cluster credentials

# 3. Deploy
terraform init
terraform plan
terraform apply
```

### 3. Access Your Cluster
After deployment, you'll get:
- **Cluster UI**: `https://your-prefix.your-domain.com:8443`
- **API**: `https://your-prefix.your-domain.com:9443`
- **Sample Database**: `redis-12000.your-prefix.your-domain.com:12000`

## ⚙️ Configuration

### Required Variables
```hcl
# Project Settings
user_prefix  = "your-name"           # Your unique identifier
cluster_name = "redis-ent"           # Cluster name
owner        = "your-name"           # Owner tag

# AWS Configuration
aws_region            = "us-west-2"
key_name              = "your-ec2-key"
ssh_private_key_path  = "~/path/to/key.pem"
dns_hosted_zone_id    = "YOUR_HOSTED_ZONE_ID"

# Redis Enterprise
re_download_url = "https://s3.amazonaws.com/redis-enterprise-software-downloads/..."
cluster_username = "admin@admin.com"
cluster_password = "SecurePassword123"  # Alphanumeric only (letters and numbers)
```

### Platform Selection
```hcl
platform = "ubuntu"  # or "rhel"
```

### Optional Settings
```hcl
# Cluster Configuration
node_count    = 3              # 3, 5, 7, or 9 nodes
instance_type = "t3.xlarge"    # 16GB RAM (good for testing)
rack_awareness = true          # Enable HA across AZs
use_elastic_ips = false        # Persistent public IPs

# Network (auto-configured)
availability_zones = []        # Auto-select or specify AZs
```


## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Public Subnet  │  │  Public Subnet  │  │  Public Subnet  │ │
│  │     (AZ-1)      │  │     (AZ-2)      │  │     (AZ-3)      │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │Redis Node 1 │ │  │ │Redis Node 2 │ │  │ │Redis Node 3 │ │ │
│  │ │(Primary)    │ │  │ │(Replica)    │ │  │ │(Replica)    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────────────┐
                    │   Route53 DNS   │
                    │ *.prefix.domain │
                    └─────────────────┘
```

**Features:**
- **Multi-Platform**: Ubuntu 22.04 or RHEL 9
- **High Availability**: 3-node cluster with rack awareness
- **DNS Integration**: Automatic Route53 records with Redis Enterprise requirements
- **Security**: VPC isolation, security groups, EBS encryption
- **Validation**: Comprehensive cluster health checks

## 🔧 Prerequisites Setup

### AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Test access
aws sts get-caller-identity
aws route53 get-hosted-zone --id YOUR_HOSTED_ZONE_ID
```

### SSH Key Setup
```bash
# Create key pair in your target region
aws ec2 create-key-pair \
    --key-name your-name-aws-us-west-2 \
    --query 'KeyMaterial' \
    --output text > ~/desktop/keys/your-key.pem

# Set permissions
chmod 400 ~/desktop/keys/your-key.pem
```

### Redis Enterprise Download URL
1. Visit [Redis Enterprise Downloads](https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/supported-platforms/)
2. Choose your platform (Ubuntu/RHEL) and version
3. Copy the download URL to your `terraform.tfvars`

## 🔍 Management

### Useful Commands
```bash
# Check cluster status
ssh -i ~/key.pem ubuntu@node-ip 'sudo /opt/redislabs/bin/rladmin status'

# Test database connection
redis-cli -h redis-12000.prefix.domain.com -p 12000 ping

# View cluster information
ssh -i ~/key.pem ubuntu@node-ip 'sudo /opt/redislabs/bin/rladmin info cluster'
```

### Accessing the UI
- **URL**: `https://your-prefix.your-domain.com:8443`
- **Username**: Your configured admin email
- **Password**: Your configured password

## 🚨 Troubleshooting

### Common Issues
1. **DNS not resolving**: Check Route53 zone ID and ensure domain delegation
2. **SSH connection failed**: Verify key pair exists in the correct AWS region
3. **Cluster join failed**: Check security groups and network connectivity
4. **Install timeout**: Increase timeout or check instance size

### Getting Help
```bash
# Check terraform outputs for connection info
terraform output

# View detailed logs
terraform apply -detailed-exitcode
```

## 📊 Deployment Time
- **Total**: ~8-10 minutes
- **Infrastructure**: ~2 minutes (parallel)
- **Software Installation**: ~3-5 minutes (parallel)
- **Cluster Bootstrap**: ~3-5 minutes (sequential)

## 🎯 What's Different in v2
- **Simplified Structure**: Flattened module hierarchy (7 vs 9 modules)
- **Integrated AMI Selection**: No separate module needed
- **Streamlined README**: Focused on quick start and essential info
- **Consolidated Outputs**: Grouped related information

## 📝 Module Structure
```
.
├── main.tf                    # Main configuration
├── variables.tf              # Input variables  
├── outputs.tf               # Output values
├── terraform.tfvars.example # Configuration template
└── modules/
    ├── vpc/                 # VPC and networking
    ├── security_groups/     # Security group rules
    ├── dns/                 # Route53 DNS records
    ├── redis_instances/     # EC2 instances + AMI selection
    ├── storage/             # EBS volumes
    ├── user_data/           # Instance user data scripts
    ├── redis_enterprise_install/ # Software installation
    ├── cluster_bootstrap/   # Cluster creation and joining
    └── database_management/ # Database creation
```

## 🔒 Security Notes
- Use strong passwords (alphanumeric only - no special characters)
- Restrict SSH access to your IP only
- Store sensitive values securely
- Never commit `terraform.tfvars` to git

---
**⚠️ Important**: This creates real AWS resources that incur costs. Remember to run `terraform destroy` when done testing.
