# Redis Enterprise Software on AWS - Load Balancer Deployment

Deploy a production-ready Redis Enterprise Software cluster on AWS with multiple load balancer options: AWS Network Load Balancer (NLB), NGINX, and HAProxy.

## 🚀 Quick Start

### 1. Prerequisites
- **AWS Account** with credentials configured (`aws configure`)
- **Terraform** >= 1.0
- **EC2 Key Pair** in your target region

### 2. Deploy in 3 Steps

```bash
# 1. Clone and configure
git clone <repository-url>
cd redis-enterprise-software-aws-lb
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars (see Configuration section)
# Required: user_prefix, cluster_name, aws_region, key_name,
#           ssh_private_key_path, load_balancer_type, re_download_url, cluster credentials

# 3. Deploy
terraform init
terraform plan
terraform apply
```

### 3. Access Your Cluster
After deployment, you'll get:
- **Cluster UI**: Via load balancer endpoint on port 8443 (or 443 for NGINX)
- **API**: Via load balancer endpoint on port 9443
- **Sample Database**: Via load balancer endpoint on port 12000

## ⚙️ Configuration

### Required Variables
```hcl
# Project Settings
user_prefix  = "your-name"           # Your unique identifier
cluster_name = "redis-ent"           # Cluster name
owner        = "your-name"           # Owner tag

# AWS Configuration
aws_region           = "us-west-2"
key_name             = "your-ec2-key"
ssh_private_key_path = "~/path/to/key.pem"

# Load Balancer Selection (IMPORTANT: Choose one)
load_balancer_type = "nlb"           # Options: "nlb", "nginx", "haproxy"

# Platform Selection
platform = "ubuntu"                  # or "rhel"

# Redis Enterprise
re_download_url = "https://s3.amazonaws.com/redis-enterprise-software-downloads/..."
cluster_username = "admin@admin.com"
cluster_password = "SecurePassword123"  # Alphanumeric only (letters and numbers)
```

### Optional Settings
```hcl
# Cluster Configuration
node_count      = 3              # 3, 5, 7, or 9 nodes
instance_type   = "t3.xlarge"    # 16GB RAM (good for testing)
rack_awareness  = true           # Enable HA across AZs
use_elastic_ips = false          # Persistent public IPs

# Network (auto-configured)
availability_zones = []          # Auto-select or specify AZs
```

## 🔧 Load Balancer Options

### 1. AWS Network Load Balancer (NLB) - Recommended

**Best For:** Production environments, minimal management overhead

**Advantages:**
- Fully managed by AWS
- High performance and low latency
- Automatic health checks and scaling
- No additional EC2 instances required

**Configuration:**
```hcl
load_balancer_type = "nlb"
```

**Access After Deploy:**
- UI: `https://<nlb-dns-name>:8443`
- API: `https://<nlb-dns-name>:9443`
- Database: `redis-cli -h <nlb-dns-name> -p 12000`

---

### 2. NGINX Load Balancer

**Best For:** Custom load balancing logic, SSL termination, advanced routing

**Advantages:**
- Full control over configuration
- Advanced load balancing methods (least_conn, ip_hash, etc.)
- Custom health checks
- Multiple NGINX instances for HA

**Configuration:**
```hcl
load_balancer_type = "nginx"

# NGINX-specific settings
nginx_instance_count = 2              # Number of NGINX instances (HA)
nginx_instance_type = "t3.medium"     # Instance size

# Port mapping (frontend = client-facing, backend = Redis Enterprise internal)
frontend_database_port = 6379         # Client connects here
backend_database_port  = 12000        # Redis Enterprise actual port
frontend_api_port      = 9443
backend_api_port       = 9443
frontend_ui_port       = 443          # Standard HTTPS
backend_ui_port        = 8443         # Redis Enterprise UI port

# Load balancing methods
database_lb_method = "least_conn"     # least_conn, round_robin, ip_hash, hash
api_lb_method      = "round_robin"
ui_lb_method       = "ip_hash"        # Sticky sessions for UI

# Health checks
max_fails     = 3                     # Failed attempts before marking unavailable
fail_timeout  = "30s"                 # Time server marked unavailable
proxy_timeout = "1s"                  # Connection timeout

# Database port range (for multiple databases)
database_port_range_start = 12000     # Start of port range
database_port_range_end   = 12010     # End of port range
```

**Access After Deploy:**
- UI: `https://<nginx-ip>:443`
- API: `https://<nginx-ip>:9443`
- Database: `redis-cli -h <nginx-ip> -p 6379`

---

### 3. HAProxy Load Balancer

**Best For:** High-performance TCP load balancing with fine-grained control

**Configuration:**
```hcl
load_balancer_type = "haproxy"
haproxy_instance_type = "t3.medium"   # Instance size
```

**Access After Deploy:**
- UI: `https://<haproxy-ip>:8443`
- API: `https://<haproxy-ip>:9443`
- Database: `redis-cli -h <haproxy-ip> -p 12000`

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
                    │  Load Balancer  │
                    │ NLB/NGINX/      │
                    │   HAProxy       │
                    └─────────────────┘
```

**Features:**
- **Multi-Platform**: Ubuntu 22.04 or RHEL 9
- **High Availability**: 3-node cluster with rack awareness across AZs
- **Load Balancer Options**: NLB (managed) or NGINX/HAProxy (self-managed)
- **Security**: VPC isolation, security groups, EBS encryption
- **Validation**: Comprehensive cluster health checks

## 🔧 Prerequisites Setup

### AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Test access
aws sts get-caller-identity
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

# Test database connection via load balancer
redis-cli -h <load-balancer-endpoint> -p 12000 ping

# View cluster information
ssh -i ~/key.pem ubuntu@node-ip 'sudo /opt/redislabs/bin/rladmin info cluster'
```

### Accessing the UI
- **NLB**: `https://<nlb-dns-name>:8443`
- **NGINX**: `https://<nginx-ip>:443`
- **HAProxy**: `https://<haproxy-ip>:8443`
- **Username**: Your configured admin email
- **Password**: Your configured password

## 🚨 Troubleshooting

### Common Issues
1. **Connection timeouts**: Check security group rules allow traffic from your IP
2. **Load balancer health check failures**: Verify Redis Enterprise nodes are healthy
3. **SSH connection failed**: Verify key pair exists in the correct AWS region
4. **Cluster join failed**: Check security groups and network connectivity

### Getting Help
```bash
# Check terraform outputs for connection info
terraform output

# View cluster validation status
terraform output cluster_validation_status
```

## 📊 Deployment Time
- **Total**: ~8-10 minutes
- **Infrastructure**: ~2 minutes (parallel)
- **Software Installation**: ~3-5 minutes (parallel)
- **Cluster Bootstrap**: ~3-5 minutes (sequential)

## 📝 Configuration Examples

### Development Environment
```hcl
load_balancer_type = "nlb"           # Simple managed solution
node_count = 3
instance_type = "t3.xlarge"          # 16GB RAM
```

### Production Environment
```hcl
load_balancer_type = "nginx"         # Full control
nginx_instance_count = 2             # HA load balancers
node_count = 3
instance_type = "r6i.2xlarge"        # 64GB RAM
use_elastic_ips = true               # Persistent IPs
```

## 📝 Module Structure
```
.
├── main.tf                    # Main configuration
├── variables.tf              # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars.example # Configuration template
└── modules/
    ├── vpc/                        # VPC and networking
    ├── security_groups/            # Security group rules
    ├── redis_instances/            # EC2 instances + AMI selection
    ├── storage/                    # EBS volumes
    ├── user_data/                  # Instance user data scripts
    ├── redis_enterprise_install/   # Software installation
    ├── cluster_bootstrap/          # Cluster creation and joining
    ├── database_management/        # Database creation
    └── infrastructure/
        └── load_balancer/          # Load balancer modules
            ├── nlb/                # Network Load Balancer
            ├── nginx/              # NGINX configuration
            └── haproxy/            # HAProxy configuration
```

## 🔒 Security Notes
- Use strong passwords (alphanumeric only - no special characters)
- Restrict SSH access to your IP only: `allow_ssh_from = ["YOUR.IP/32"]`
- Store sensitive values securely
- Never commit `terraform.tfvars` to git

---
**⚠️ Important**: This creates real AWS resources that incur costs. Remember to run `terraform destroy` when done testing.
