# Redis Enterprise Software on AWS - Terraform Deployment

This Terraform project deploys a highly available Redis Enterprise Software cluster on AWS with automatic DNS configuration, platform selection (Ubuntu/RHEL), and production-ready security settings.

## 🚀 Features

- **Multi-Platform Support**: Choose between Ubuntu 22.04 or RHEL 9
- **High Availability**: 3-node cluster with rack awareness and replication
- **Simplified DNS**: Follows Redis Enterprise documentation with single domain
- **Flexible Configuration**: Separate `user_prefix` + `cluster_name` variables
- **Availability Zone Selection**: Choose specific AZs or auto-select multi-AZ
- **Optional Elastic IPs**: Persistent public IPs for stop/start capability
- **Comprehensive Validation**: Ensures all nodes join cluster successfully
- **Security**: Comprehensive security groups with minimal required access
- **Storage**: Optimized EBS volumes with encryption
- **Monitoring**: Built-in metrics and health checking
- **Sample Database**: Auto-created Redis database for testing

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **Route53 Hosted Zone** for DNS records
5. **EC2 Key Pair** for SSH access
6. **Redis Enterprise Download URL** (see Configuration section)

### ✅ Pre-Deployment Validation

Before running Terraform, verify your AWS credentials are properly configured:

```bash
# Test AWS credentials and permissions
aws sts get-caller-identity

# Expected output (with your actual account details):
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }

# Test Route53 access (replace with your hosted zone ID)
aws route53 get-hosted-zone --id YOUR_HOSTED_ZONE_ID

# Test EC2 access in your target region
aws ec2 describe-availability-zones --region us-west-2
```

**If any of these commands fail, fix your AWS credentials before proceeding with Terraform.**

### 🔧 AWS Credentials Troubleshooting

If you get errors like `no EC2 IMDS role found` or `credential errors`:

#### Option 1: AWS CLI Configuration (Recommended)
```bash
# Configure AWS CLI with your credentials
aws configure

# This will prompt for:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region name
# - Default output format (json)
```

#### Option 2: Environment Variables
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

#### Option 3: AWS Profile
```bash
# If using named profiles
export AWS_PROFILE=your-profile-name

# Verify profile is working
aws sts get-caller-identity --profile your-profile-name
```

#### Common Issues:
- **Missing credentials**: Run `aws configure` to set them up
- **Wrong region**: Ensure your AWS region matches your terraform.tfvars
- **Insufficient permissions**: Your AWS user needs EC2, Route53, and VPC permissions
- **Credential file location**: Should be in `~/.aws/credentials`

### 🔑 SSH Key Pair Setup

**Important**: The EC2 Key Pair must be created in the same AWS region where you're deploying the cluster.

#### Create SSH Key Pair via AWS Console:
1. Go to **EC2 Console** → **Key Pairs** in your target region
2. Click **Create key pair**
3. Name: `your-name-aws-region` (e.g., `alice-aws-us-west-2`)
4. Type: **RSA** or **ED25519**
5. Format: **.pem**
6. Download the `.pem` file to a secure location

#### Create SSH Key Pair via AWS CLI:
```bash
# Set your target region
export AWS_REGION=us-west-2

# Create key pair and save to file
aws ec2 create-key-pair \
    --key-name your-name-aws-${AWS_REGION} \
    --query 'KeyMaterial' \
    --output text > ~/desktop/keys/your-name-aws-${AWS_REGION}.pem

# Verify key pair was created
aws ec2 describe-key-pairs --key-names your-name-aws-${AWS_REGION}
```

#### Set Correct Permissions:
```bash
# SSH requires strict permissions on private key files
chmod 400 ~/desktop/keys/your-name-aws-us-west-2.pem

# Verify permissions (should show: -r--------)
ls -la ~/desktop/keys/your-name-aws-us-west-2.pem
```

#### Update terraform.tfvars:
```hcl
# Match these exactly to your key pair
aws_region           = "us-west-2"  # Same region where key was created
key_name             = "your-name-aws-us-west-2"  # Exact key pair name in AWS
ssh_private_key_path = "~/desktop/keys/your-name-aws-us-west-2.pem"  # Local file path
```

#### Test SSH Key:
```bash
# After deployment, test SSH access (replace with actual node IP)
ssh -i ~/desktop/keys/your-name-aws-us-west-2.pem ubuntu@<node-ip>

# Should connect without password prompt
# If you get permission denied, check:
# 1. Key permissions (chmod 400)
# 2. Key name matches terraform.tfvars
# 3. Key exists in correct AWS region
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Public Subnet  │  │  Public Subnet  │  │  Public Subnet  │ │
│  │     (AZ-1)      │  │     (AZ-2)      │  │     (AZ-3)      │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │Redis Node 1 │ │  │ │Redis Node 2 │ │  │ │Redis Node 3 │ │ │
│  │ │(Primary)    │ │  │ │(Replica)    │ │  │ │(Replica)    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────────────┐
                    │   Route53 DNS   │
                    │                 │
                    │ Cluster UI:     │
                    │ prefix.domain   │
                    │                 │
                    │ Nodes:          │
                    │ node1.prefix... │
                    │ node2.prefix... │
                    │ node3.prefix... │
                    │                 │
                    │ Databases:      │
                    │ *.prefix.domain │
                    └─────────────────┘
```

## 🛠️ Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd redis-enterprise-software-aws
cp terraform.tfvars.example terraform.tfvars
```

### 2. Update Configuration

Edit `terraform.tfvars`:

```hcl
# Required: Project Configuration
user_prefix    = "your-name"           # Your unique identifier (e.g., "alice")
cluster_name   = "redis-ent"          # Cluster name suffix
owner          = "your-name"          # Your name/team

# Required: AWS Configuration
aws_region            = "us-west-2"               # Your AWS region
key_name              = "your-ec2-key"            # Your EC2 key pair
ssh_private_key_path  = "path/to/your/key.pem"    # Path to private key
dns_hosted_zone_id    = "YOUR_ROUTE53_HOSTED_ZONE_ID"  # Your Route53 zone ID

# Optional: Availability Zone Selection
availability_zones = []  # Auto-select multi-AZ, or specify: ["us-west-2a", "us-west-2b", "us-west-2c"]

# Optional: Elastic IPs (for persistent public IPs)
use_elastic_ips = false  # Set to true if you need persistent IPs for stop/start

# Choose platform: "ubuntu" or "rhel"
platform = "ubuntu"

# Required: Redis Enterprise download URL (get from Redis documentation)
re_download_url = "REPLACE_WITH_YOUR_REDIS_ENTERPRISE_DOWNLOAD_URL"

# Security: Update with strong credentials
cluster_username = "admin@your-domain.com"
cluster_password = "YourStrongPassword123!"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Your Cluster

After deployment, you'll see outputs with:
- **Cluster UI**: `https://user-prefix-cluster-name.your-domain.com:8443`
- **SSH Commands**: Connect to individual nodes
- **Database Connection**: `redis-cli -h redis-12000.user-prefix-cluster-name.your-domain.com -p 12000`

## ⚙️ Configuration Options

### Platform Selection

Choose between Ubuntu 22.04 LTS or RHEL 9:

```hcl
# Ubuntu (recommended for testing)
platform = "ubuntu"
re_download_url = "REPLACE_WITH_UBUNTU_REDIS_ENTERPRISE_DOWNLOAD_URL"

# RHEL 9 (enterprise production)
platform = "rhel" 
re_download_url = "REPLACE_WITH_RHEL_REDIS_ENTERPRISE_DOWNLOAD_URL"
```

### Getting Redis Enterprise Download URLs

1. Visit [Redis Enterprise Supported Platforms](https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/supported-platforms/)
2. Choose your desired version and platform
3. Copy the download URL to your `terraform.tfvars`

### DNS Naming Convention

With `user_prefix = "alice"`, `cluster_name = "redis-ent"` and domain `example.com`:

- **Cluster UI**: `https://alice-redis-ent.example.com:8443`
- **API**: `https://alice-redis-ent.example.com:9443`
- **Nodes**: `alice-redis-ent-node-1`, `alice-redis-ent-node-2`, etc.
- **Databases**: `redis-12000.alice-redis-ent.example.com` (wildcards supported)

### Availability Zone Selection

```hcl
# Automatic multi-AZ selection (recommended)
availability_zones = []

# Specific AZs for multi-AZ deployment
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Single AZ deployment (for testing)
availability_zones = ["us-west-2a"]
```

### Elastic IP Configuration

```hcl
# Enable Elastic IPs for persistent public addresses
use_elastic_ips = true   # Allows stop/start without IP changes

# Disable for cost savings (default)
use_elastic_ips = false  # Uses dynamic public IPs
```

### Cluster Sizing

```hcl
# Development/Testing
node_count    = 3
instance_type = "t3.xlarge"    # 16GB RAM

# Production
node_count    = 3              # or 5, 7, 9 for larger clusters
instance_type = "r6i.2xlarge"  # 64GB RAM
```

### Storage Configuration

```hcl
# EBS volumes are automatically sized based on instance RAM
data_volume_size       = 64    # RAM × 4 for optimal performance
persistent_volume_size = 64    # Same as data volume
ebs_encryption_enabled = true  # Always recommended
```

## 🔒 Security

### Default Security Configuration

- **SSH Access**: Restricted to specified CIDR blocks
- **Redis UI/API**: Same restriction as SSH
- **Database Ports**: Open within VPC + specified external IPs
- **Internal Communication**: Cluster nodes only
- **EBS Encryption**: Enabled by default

### Production Security Checklist

1. **Restrict SSH access** to your IP only:
   ```hcl
   allow_ssh_from = ["YOUR.IP.ADDRESS/32"]
   ```

2. **Use strong passwords**:
   ```hcl
   cluster_password = "ComplexPassword123!@#"
   ```

3. **Never commit sensitive data**:
   - Add `terraform.tfvars` to `.gitignore`
   - Use AWS Parameter Store for production secrets

4. **Enable additional security**:
   ```hcl
   rack_awareness = true  # Distribute replicas across AZs
   ```

## ✅ Cluster Validation

This terraform includes comprehensive validation to ensure all nodes join the cluster successfully:

- **Automatic Node Validation**: Verifies all nodes are online and joined
- **Retry Logic**: Attempts cluster formation multiple times if needed  
- **Health Checks**: Validates cluster state and database creation
- **Clear Error Messages**: Provides debugging information if validation fails

The validation output shows:
```
✅ Cluster validation ensures all 3 Redis Enterprise nodes joined successfully via rladmin status checks
```

## 📊 Monitoring & Management

### Useful Commands

```bash
# Check cluster status
ssh -i key.pem ubuntu@node1.prefix.domain.com 'sudo /opt/redislabs/bin/rladmin status'

# View cluster information
ssh -i key.pem ubuntu@node1.prefix.domain.com 'sudo /opt/redislabs/bin/rladmin info cluster'

# List databases
ssh -i key.pem ubuntu@node1.prefix.domain.com 'sudo /opt/redislabs/bin/rladmin status databases'

# Monitor logs
ssh -i key.pem ubuntu@node1.prefix.domain.com 'sudo tail -f /var/opt/redislabs/log/supervisor/*.log'
```

### Testing Database Connectivity

```bash
# External connection
redis-cli -h redis-12000.user-prefix-cluster-name.your-domain.com -p 12000 ping

# Internal/VPC connection
redis-cli -h redis-12000-internal.user-prefix-cluster-name.your-domain.com -p 12000 ping

# Direct IP connection (backup)
redis-cli -h <node-ip> -p 12000 ping

# Test basic operations
redis-cli -h redis-12000.user-prefix-cluster-name.your-domain.com -p 12000
> SET test "Hello Redis Enterprise"
> GET test
```

## 🚨 Troubleshooting

### Common Issues

1. **DNS Resolution Failure**
   ```bash
   # Check DNS records
   dig redis-12000.user-prefix-cluster-name.your-domain.com
   
   # Check NS delegation
   dig user-prefix-cluster-name.your-domain.com NS
   
   # Verify Route53 zone ID
   aws route53 list-hosted-zones
   ```

2. **Service Issues**
   ```bash
   # Check Redis Enterprise cluster status
   ssh -i key.pem ubuntu@node-ip 'sudo /opt/redislabs/bin/rladmin status'
   ```

### Log Locations

- **Cluster logs**: `/var/opt/redislabs/log/supervisor/`
- **Installation logs**: `/tmp/redis_enterprise_install.log`
- **Platform setup logs**: `/tmp/basic_setup.log`

## 🔄 Upgrades & Maintenance

### Upgrading Redis Enterprise

1. Update `re_download_url` in `terraform.tfvars`
2. Run `terraform plan` to see changes
3. Apply with `terraform apply`

### Scaling the Cluster

```hcl
# Add more nodes (always use odd numbers: 3, 5, 7, 9)
node_count = 5

# Increase instance sizes
instance_type = "r6i.4xlarge"  # 128GB RAM
```

### Backup Strategy

- **Automated backups**: Configure through Redis Enterprise UI
- **Infrastructure**: Use `terraform state` backups
- **DNS**: Route53 records are recreated on apply

## 📝 Module Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf              # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars.example # Example configuration
├── modules/
│   ├── vpc/                 # VPC and networking
│   ├── security_group/      # Security group rules
│   ├── dns/                 # Route53 DNS records
│   └── redis_enterprise_cluster/  # Redis Enterprise cluster
└── scripts/
    ├── install_ubuntu.sh    # Ubuntu installation script
    ├── install_rhel.sh      # RHEL installation script
    ├── basic_setup_ubuntu.sh  # Ubuntu platform setup
    └── basic_setup_rhel.sh    # RHEL platform setup
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review [Redis Enterprise documentation](https://redis.io/docs/latest/operate/rs/)
3. Open an issue in the repository

---

**⚠️ Important**: Never commit `terraform.tfvars` to version control as it contains sensitive information like passwords and private keys.