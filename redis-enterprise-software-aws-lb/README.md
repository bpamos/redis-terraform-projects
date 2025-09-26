# Redis Enterprise Software on AWS - Load Balancer Deployment

This Terraform project deploys a highly available Redis Enterprise Software cluster on AWS with multiple load balancer options: AWS Network Load Balancer (NLB), NGINX, and HAProxy.

## 🚀 Features

- **Multiple Load Balancer Options**: Choose between NLB (managed), NGINX (self-managed), or HAProxy (self-managed)
- **Multi-Platform Support**: Choose between Ubuntu 22.04 or RHEL 9
- **High Availability**: 3-node Redis Enterprise cluster with rack awareness
- **Security**: Comprehensive security groups with minimal required access
- **Storage**: Optimized EBS volumes with encryption
- **Monitoring**: Built-in metrics and health checking
- **Sample Database**: Auto-created Redis database for testing

## 🏗️ Architecture

### Default Architecture with Load Balancer

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                             │
│                                                             │
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
                    │  Load Balancer  │
                    │                 │
                    │  NLB / NGINX /  │
                    │     HAProxy     │
                    │                 │
                    │ Database: 6379  │
                    │ API: 9443       │
                    │ UI: 443         │
                    └─────────────────┘
```

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **EC2 Key Pair** for SSH access
5. **Redis Enterprise Download URL** (see Configuration section)

## 🛠️ Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd redis-enterprise-software-aws-lb
cp terraform.tfvars.example terraform.tfvars
```

### 2. Update Configuration

Edit `terraform.tfvars`:

```hcl
# Required: Update these values
name_prefix            = "your-redis-cluster"      # Your unique cluster name
owner                  = "your-name"               # Your name/team
aws_region            = "us-west-2"               # Your AWS region
key_name              = "your-ec2-key"            # Your EC2 key pair
ssh_private_key_path  = "path/to/your/key.pem"    # Path to private key

# Load Balancer Selection
load_balancer_type = "nlb"    # Options: "nlb", "nginx", "haproxy"

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
- **Database Connection**: `redis-cli -h <load-balancer-ip> -p 6379`
- **Cluster UI**: `https://<load-balancer-ip>:443`
- **API Endpoint**: `https://<load-balancer-ip>:9443`
- **SSH Commands**: Connect to individual nodes

## ⚙️ Load Balancer Options

### 1. AWS Network Load Balancer (NLB) - Recommended

**Advantages:**
- Fully managed by AWS
- High performance and low latency
- Automatic health checks
- Scales automatically

**Configuration:**
```hcl
load_balancer_type = "nlb"
```

**Use Cases:**
- Production environments
- High traffic applications
- Minimal management overhead required

### 2. NGINX Load Balancer

**Advantages:**
- Full control over configuration
- Advanced load balancing methods
- SSL termination
- Custom health checks

**Configuration:**
```hcl
load_balancer_type = "nginx"
nginx_instance_count = 2              # High availability
nginx_instance_type = "t3.medium"     # Instance size

# Load balancing methods
database_lb_method = "least_conn"     # least_conn, round_robin, ip_hash, hash
api_lb_method = "round_robin"         
ui_lb_method = "ip_hash"              # Sticky sessions for UI

# Port configuration
frontend_database_port = 6379         # Client-facing port
backend_database_port = 12000         # Redis Enterprise port
frontend_api_port = 9443
backend_api_port = 9443
frontend_ui_port = 443
backend_ui_port = 8443

# Health check configuration
max_fails = 3                         # Failed attempts before marking unavailable
fail_timeout = "30s"                  # Time server marked unavailable
proxy_timeout = "1s"                  # Connection timeout
```

**Use Cases:**
- Need custom load balancing logic
- SSL/TLS termination requirements
- Advanced traffic routing

### 3. HAProxy Load Balancer (Currently Excluded)

HAProxy configuration is available but not covered in this README as requested.

## 🔧 Platform Selection

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

## 🔒 Security

### Default Security Configuration

- **SSH Access**: Restricted to specified CIDR blocks
- **Load Balancer Access**: Configurable access from specified IPs
- **Internal Communication**: Cluster nodes only
- **EBS Encryption**: Enabled by default

### Production Security Checklist

1. **Restrict access** to your IP only:
   ```hcl
   allow_ssh_from = ["YOUR.IP.ADDRESS/32"]
   allow_access_from = ["YOUR.IP.ADDRESS/32"]
   ```

2. **Use strong passwords**:
   ```hcl
   cluster_password = "ComplexPassword123!@#"
   ```

3. **Never commit sensitive data**:
   - Add `terraform.tfvars` to `.gitignore`
   - Use AWS Parameter Store for production secrets

## 📊 Testing & Monitoring

### Database Connection Testing

```bash
# Test database connection through load balancer
redis-cli -h <load-balancer-ip> -p 6379 ping

# Test basic operations
redis-cli -h <load-balancer-ip> -p 6379
> SET test "Hello Redis Enterprise"
> GET test

# Test from multiple clients to verify load balancing
for i in {1..10}; do
  redis-cli -h <load-balancer-ip> -p 6379 CLIENT LIST | grep addr
done
```

### API Access

```bash
# Test API endpoint through load balancer
curl -k -u admin:password https://<load-balancer-ip>:9443/v1/cluster

# Test UI access
open https://<load-balancer-ip>:443
```

### Load Balancer Health

**For NLB:**
```bash
# Check target group health in AWS Console
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

**For NGINX:**
```bash
# Check NGINX status
ssh -i key.pem ubuntu@<nginx-lb-ip> 'sudo systemctl status nginx'

# Check NGINX logs
ssh -i key.pem ubuntu@<nginx-lb-ip> 'sudo tail -f /var/log/nginx/error.log'
```

## 🚨 Troubleshooting

### Common Issues

1. **Connection Timeouts**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids <sg-id>
   
   # Test connectivity
   telnet <load-balancer-ip> 6379
   ```

2. **Load Balancer Health Check Failures**
   ```bash
   # For NLB: Check target group health
   # For NGINX: Check backend server connectivity
   ssh -i key.pem ubuntu@<nginx-ip> 'curl -v http://<redis-node-ip>:12000'
   ```

3. **SSL/TLS Issues**
   ```bash
   # Test SSL connectivity
   openssl s_client -connect <load-balancer-ip>:443
   ```

### Log Locations

- **Redis Enterprise**: `/var/opt/redislabs/log/supervisor/`
- **NGINX**: `/var/log/nginx/`
- **Installation logs**: `/tmp/redis_enterprise_install.log`

## 📝 Configuration Examples

### Development Environment
```hcl
load_balancer_type = "nlb"           # Simple managed solution
node_count = 3
instance_type = "t3.xlarge"         # 16GB RAM
```

### Production Environment
```hcl
load_balancer_type = "nginx"        # Full control
nginx_instance_count = 2            # HA load balancers
nginx_instance_type = "t3.large"    # More capacity
node_count = 3
instance_type = "r6i.2xlarge"       # 64GB RAM
```

### High-Performance Environment
```hcl
load_balancer_type = "nlb"          # Lowest latency
node_count = 5                      # Larger cluster
instance_type = "r6i.4xlarge"       # 128GB RAM
```

## 🔄 Upgrades & Maintenance

### Upgrading Redis Enterprise

1. Update `re_download_url` in `terraform.tfvars`
2. Run `terraform plan` to see changes
3. Apply with `terraform apply`

### Scaling Load Balancers

**For NLB:** Automatic scaling by AWS
**For NGINX:**
```hcl
nginx_instance_count = 3  # Increase for more capacity
nginx_instance_type = "t3.large"  # Larger instances
```

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review [Redis Enterprise documentation](https://redis.io/docs/latest/operate/rs/)
3. Open an issue in the repository

---

**⚠️ Important**: Never commit `terraform.tfvars` to version control as it contains sensitive information like passwords and private keys.