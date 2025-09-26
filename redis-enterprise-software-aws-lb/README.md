# Redis Enterprise Software on AWS - Terraform Deployment

This Terraform project deploys a highly available Redis Enterprise Software cluster on AWS with automatic DNS configuration, platform selection (Ubuntu/RHEL), and production-ready security settings.

## 🚀 Features

- **Multi-Platform Support**: Choose between Ubuntu 22.04 or RHEL 9
- **High Availability**: 3-node cluster with rack awareness and replication
- **DNS Integration**: Automatic Route53 DNS records with custom naming
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
# Required: Update these values
name_prefix            = "your-redis-cluster"      # Your unique cluster name
owner                  = "your-name"               # Your name/team
aws_region            = "us-west-2"               # Your AWS region
key_name              = "your-ec2-key"            # Your EC2 key pair
ssh_private_key_path  = "path/to/your/key.pem"    # Path to private key
dns_hosted_zone_id    = "YOUR_ROUTE53_HOSTED_ZONE_ID"  # Your Route53 zone ID

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
- **Cluster UI**: `https://your-prefix.your-domain.com:8443`
- **SSH Commands**: Connect to individual nodes
- **Database Connection**: `redis-cli -h demo-12000.your-prefix.your-domain.com -p 12000`

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

With `name_prefix = "my-redis"` and domain `example.com`:

- **Cluster UI**: `https://my-redis.example.com:8443`
- **API**: `https://my-redis.example.com:9443`
- **Nodes**: `node1.my-redis.example.com`, `node2.my-redis.example.com`, etc.
- **Databases**: `demo-12000.my-redis.example.com` (wildcards supported)

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
redis-cli -h demo-12000.your-prefix.your-domain.com -p 12000 ping

# Direct IP connection (backup)
redis-cli -h <node-ip> -p 12000 ping

# Test basic operations
redis-cli -h demo-12000.your-prefix.your-domain.com -p 12000
> SET test "Hello Redis Enterprise"
> GET test
```

## 🚨 Troubleshooting

### Common Issues

1. **DNS Resolution Failure**
   ```bash
   # Check DNS records
   dig demo-12000.your-prefix.your-domain.com
   
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