# Redis Enterprise Active-Active Multi-Region Deployment

Deploy geo-distributed Redis Enterprise Software clusters with automated Active-Active (CRDB) databases across multiple AWS regions.

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with credentials configured
2. **Terraform** >= 1.0
3. **Route53 Hosted Zone** for DNS
4. **EC2 Key Pairs** in ALL target regions
5. **Redis Enterprise Download URL** from [redis.io](https://redis.io/downloads/)

### Deploy in 3 Steps

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 2. Initialize
terraform init

# 3. Deploy
terraform apply
```

**Deployment time:** 15-20 minutes

---

## 📋 What This Deploys

### Infrastructure Per Region
- ✅ VPC with public and private subnets across 3 AZs
- ✅ 3-node Redis Enterprise cluster (configurable)
- ✅ Security groups for cluster and cross-region communication
- ✅ DNS records (regional FQDNs)
- ✅ NTP/Chrony for time synchronization

### Multi-Region Components
- ✅ VPC peering mesh between all regions
- ✅ Cross-region routing for cluster communication
- ✅ Active-Active (CRDB) database across all clusters
- ✅ Automated CRDB creation and verification

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Route53 Hosted Zone                          │
│                   yourdomain.com                                │
│                                                                  │
│  NS: us-west-2.yourname-redis-aa.yourdomain.com                │
│  NS: us-east-1.yourname-redis-aa.yourdomain.com                │
└─────────────────────────────────────────────────────────────────┘
                              ↓                ↓
        ┌─────────────────────────────────────────────────┐
        │                                                  │
┌───────▼──────────┐                           ┌──────────▼───────┐
│ Region: us-west-2│◄──────VPC Peering────────►│Region: us-east-1 │
│                  │                            │                  │
│ VPC: 10.0.0.0/16 │                            │ VPC: 10.1.0.0/16 │
│                  │                            │                  │
│ Private Subnets  │                            │ Private Subnets  │
│ ┌──────────────┐ │                            │ ┌──────────────┐ │
│ │ Redis Node 1 │ │                            │ │ Redis Node 1 │ │
│ │  10.0.4.10   │ │                            │ │  10.1.4.10   │ │
│ └──────────────┘ │                            │ └──────────────┘ │
│ ┌──────────────┐ │                            │ ┌──────────────┐ │
│ │ Redis Node 2 │ │                            │ │ Redis Node 2 │ │
│ │  10.0.5.10   │ │                            │ │  10.1.5.10   │ │
│ └──────────────┘ │                            │ └──────────────┘ │
│ ┌──────────────┐ │                            │ ┌──────────────┐ │
│ │ Redis Node 3 │ │                            │ │ Redis Node 3 │ │
│ │  10.0.6.10   │ │                            │ │  10.1.6.10   │ │
│ └──────────────┘ │                            │ └──────────────┘ │
│                  │                            │                  │
│  CRDB Instance   │◄──────Replication────────►│  CRDB Instance   │
│  active-active-db│                            │  active-active-db│
└──────────────────┘                            └──────────────────┘
```

**Key Features:**
- **Private Networking:** All nodes use private IPs with VPC peering
- **HA per Region:** 3-node clusters with rack awareness
- **Active-Active:** Bi-directional replication for global consistency
- **DNS Integration:** Regional FQDNs for each cluster

---

## ⚙️ Configuration

### Minimal Configuration

```hcl
# terraform.tfvars
user_prefix = "yourname"
owner       = "Your Name"

regions = {
  "us-west-2" = {
    vpc_cidr     = "10.0.0.0/16"
    key_name     = "your-key-us-west-2"
    ssh_key_path = "~/keys/us-west-2.pem"
  }
  "us-east-1" = {
    vpc_cidr     = "10.1.0.0/16"
    key_name     = "your-key-us-east-1"
    ssh_key_path = "~/keys/us-east-1.pem"
  }
}

dns_hosted_zone_id = "Z1234567890ABC"
re_download_url    = "https://s3.amazonaws.com/.../redislabs-7.4.2-104-jammy-amd64.tar"
cluster_password   = "YourSecurePassword123"
```

### Adding More Regions

Simply add to the `regions` map:

```hcl
regions = {
  "us-west-2"  = { ... }
  "us-east-1"  = { ... }
  "eu-west-1"  = {
    vpc_cidr     = "10.2.0.0/16"
    key_name     = "your-key-eu-west-1"
    ssh_key_path = "~/keys/eu-west-1.pem"
  }
  "ap-southeast-1" = {
    vpc_cidr     = "10.3.0.0/16"
    key_name     = "your-key-ap-southeast-1"
    ssh_key_path = "~/keys/ap-southeast-1.pem"
  }
}
```

**Important:** VPC CIDRs must NOT overlap!

---

## 🔐 Security Notes

### Private IP Architecture

This deployment uses **private IPs** for Redis nodes:
- ✅ Nodes deployed in private subnets
- ✅ No public IPs assigned to Redis nodes
- ✅ VPC peering for cross-region communication
- ✅ NAT Gateway for outbound internet (software downloads)
- ⚠️ SSH access via bastion host or VPN (not included)

### Network Security

Cross-region security group rules allow:
- Port 8443 (Cluster Manager UI)
- Port 9443 (REST API - **CRITICAL for CRDB**)
- Ports 3333-3356 (Cluster coordination)
- Ports 8001, 9081 (Proxy, CRDB coordination)
- Ports 10000-19999 (Database endpoints)
- Ports 20000-29999 (Shard replication)

### Access Control

- SSH access configurable via `allow_ssh_from` CIDR list
- Cluster credentials shared across all regions
- EBS encryption enabled by default
- Sensitive outputs marked as `sensitive`

---

## 📊 Accessing Your Deployment

### After Deployment

```bash
# View outputs
terraform output

# Get cluster URLs
terraform output -json connection_info | jq
```

### Cluster Manager UI

Access from any region:
```
https://us-west-2.yourname-redis-aa.yourdomain.com:8443
https://us-east-1.yourname-redis-aa.yourdomain.com:8443
```

**Credentials:** Use your configured `cluster_username` and `cluster_password`

### Connect to CRDB Database

From any region, connect to the Active-Active database:

```bash
# us-west-2
redis-cli -h redis-12000.us-west-2.yourname-redis-aa.yourdomain.com -p 12000

# us-east-1
redis-cli -h redis-12000.us-east-1.yourname-redis-aa.yourdomain.com -p 12000

# Both instances stay synchronized!
```

### Test Active-Active Replication

```bash
# Write to us-west-2
redis-cli -h redis-12000.us-west-2.yourname-redis-aa.yourdomain.com -p 12000 \
  SET testkey "hello from west"

# Read from us-east-1 (should see the same value)
redis-cli -h redis-12000.us-east-1.yourname-redis-aa.yourdomain.com -p 12000 \
  GET testkey
# Returns: "hello from west"
```

---

## 🔍 Verification

### Check CRDB Status

```bash
# Verify CRDB exists on all clusters
for region in us-west-2 us-east-1; do
  echo "Checking $region..."
  curl -k -u "admin@admin.com:password" \
    https://$region.yourname-redis-aa.yourdomain.com:9443/v1/crdbs | jq
done
```

### Test Connectivity

```bash
# Test port 9443 connectivity between regions
telnet us-west-2.yourname-redis-aa.yourdomain.com 9443
telnet us-east-1.yourname-redis-aa.yourdomain.com 9443
```

### Verify VPC Peering

```bash
# Check peering status
terraform output vpc_peering
```

---

## 🛠️ Management

### Scaling

**Add Regions:**
1. Add new region to `regions` map in `terraform.tfvars`
2. Run `terraform apply`
3. CRDB automatically includes new region

**Scale Nodes Per Region:**
```hcl
node_count_per_region = 5  # Change from 3 to 5
```

### Upgrading Redis Enterprise

1. Update `re_download_url` in `terraform.tfvars`
2. Upgrade one cluster at a time manually
3. **Do not** run `terraform apply` for upgrades (use cluster UI)

### Destroying

```bash
# Destroy all resources
terraform destroy

# Or destroy specific region
terraform destroy -target=module.redis_cluster[\"us-west-2\"]
```

⚠️ **Warning:** Destroying will delete all data!

---

## 🧩 Module Structure

```
.
├── main.tf                          # Multi-region orchestration
├── variables.tf                     # User-facing variables
├── outputs.tf                       # Deployment outputs
├── terraform.tfvars.example         # Configuration template
└── modules/
    ├── single_region/               # Wrapper for one region deployment
    ├── vpc_peering_mesh/           # VPC peering automation
    ├── crdb_management/            # CRDB creation via API
    ├── vpc/                        # VPC infrastructure
    ├── security_groups/            # Security group rules
    ├── dns/                        # Route53 DNS records
    ├── redis_instances/            # EC2 instances
    ├── storage/                    # EBS volumes
    ├── user_data/                  # Instance initialization
    ├── redis_enterprise_install/   # Software installation
    ├── cluster_bootstrap/          # Cluster creation
    └── database_management/        # Database provisioning
```

---

## 🚨 Troubleshooting

### CRDB Creation Fails

**Check cluster connectivity:**
```bash
telnet us-east-1.yourname-redis-aa.yourdomain.com 9443
```

**Verify security groups:**
```bash
aws ec2 describe-security-groups --region us-west-2 \
  --filters "Name=tag:Name,Values=*redis-aa*"
```

**Check NTP sync:**
```bash
ssh -i key.pem ubuntu@10.0.4.10 "chronyc tracking"
```

### VPC Peering Issues

**Verify peering status:**
```bash
terraform output vpc_peering
```

**Check route tables:**
```bash
aws ec2 describe-route-tables --region us-west-2 \
  --filters "Name=tag:Name,Values=*redis-aa*"
```

### DNS Not Resolving

**Check hosted zone:**
```bash
aws route53 get-hosted-zone --id Z1234567890ABC
```

**Test DNS resolution:**
```bash
dig us-west-2.yourname-redis-aa.yourdomain.com
```

---

## 📚 Additional Resources

- [Redis Enterprise Active-Active Documentation](https://redis.io/docs/latest/operate/rs/databases/active-active/)
- [Redis Enterprise on AWS Best Practices](https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/configuring-aws-instances/)
- [VPC Peering Guide](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)

---

## 💡 Tips & Best Practices

### Production Deployment

1. **Use larger instances:** `m5.2xlarge` or `m5.4xlarge`
2. **Enable backups:** Configure persistence policies
3. **Monitor costs:** Review AWS Cost Explorer regularly
4. **Restrict SSH:** Change `allow_ssh_from` to your corporate CIDR
5. **Use VPN/Direct Connect:** For SSH access to private IPs

### Cost Optimization

- Use Reserved Instances for long-term deployments
- Consider Graviton instances (ARM-based) for cost savings
- Monitor EBS usage and adjust volume sizes

### Security Hardening

- Implement AWS PrivateLink for enhanced security
- Use AWS Secrets Manager for credential management
- Enable CloudTrail for audit logging
- Implement VPC Flow Logs

---

## 🎯 Key Differences from Single-Region Deployment

| Feature | Single-Region | Active-Active Multi-Region |
|---------|--------------|---------------------------|
| **Regions** | 1 | 2+ |
| **Networking** | Single VPC | VPC peering mesh |
| **IPs** | Public or Private | Private only |
| **Database** | Standard DB | CRDB (Active-Active) |
| **DNS** | Single FQDN | Regional FQDNs |
| **Replication** | Within cluster | Cross-region |
| **Complexity** | Low | Medium |
| **HA Level** | Regional | Global |

---

**⚠️ Important:** This creates real AWS resources that incur costs. Run `terraform destroy` when done testing.

**💰 Estimated Costs:** ~$400-600/month for 2 regions with t3.xlarge instances (24/7)
