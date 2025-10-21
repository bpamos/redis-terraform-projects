# Redis Cloud + AWS VPC - Simple Version

**The absolute simplest way to connect Redis Cloud to AWS.**

- ✅ **4 files total** - Everything you need in one folder
- ✅ **No modules** - See the entire flow in 2 main files
- ✅ **Hardcoded values** - Sensible defaults, just add credentials
- ✅ **Deploy in 5 minutes** - From zero to Redis Cloud + VPC peering

Perfect for: **Learning, testing, proof-of-concept, understanding the basics**

For production/scaling: See [`../redis-cloud-plus-aws-vpc-with-ec2/`](../redis-cloud-plus-aws-vpc-with-ec2/)

---

## What This Creates

```
┌─────────────────────────────┐    ┌──────────────────┐
│        AWS VPC              │    │   Redis Cloud    │
│      10.0.0.0/16            │    │   10.42.0.0/24   │
│                             │    │                  │
│  Public Subnets:            │◄──►│  1GB Database    │
│  • 10.0.1.0/24 (us-west-2a)│    │  RedisJSON       │
│  • 10.0.2.0/24 (us-west-2b)│    │  1000 ops/sec    │
│                             │    │  HA enabled      │
└─────────────────────────────┘    └──────────────────┘
           │                              │
           └──── VPC Peering ─────────────┘
```

**AWS Resources:**
- VPC with 2 public subnets in us-west-2
- Internet Gateway
- Route tables with Redis Cloud routing

**Redis Cloud Resources:**
- 1GB database with RedisJSON module
- High availability (replication enabled)
- 1000 operations/second throughput
- AOF persistence (append-only file every 1 second)

**Networking:**
- VPC Peering between AWS and Redis Cloud
- Private connectivity for low latency

---

## Quick Start

### 1. Get Redis Cloud API Credentials

1. Sign in to [Redis Cloud Console](https://app.redislabs.com)
2. Go to **Access Management** → **API Keys**
3. **Account Key**: Click "Show" then "Copy" (this is your API key)
4. **User Key**: Click "Add", provide name, select role, click "Create"
   Copy immediately - shown only once (this is your secret key)

### 2. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
```

**Required values:**
- `rediscloud_api_key` - Your Redis Cloud account API key
- `rediscloud_secret_key` - Your Redis Cloud user secret key
- `aws_account_id` - Your 12-digit AWS Account ID
- `credit_card_last_four` - Last 4 digits of payment method

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Get Connection Info

```bash
# Show all outputs
terraform output

# Get CLI command
terraform output -raw redis_cli_command

# Get connection details
terraform output connection_info
```

---

## Files Explained

### `aws.tf` - AWS Resources (60 lines)
Creates the AWS side of the infrastructure:
- VPC (10.0.0.0/16)
- 2 public subnets across availability zones
- Internet Gateway for public internet access
- Route table with routing to Redis Cloud
- VPC peering acceptance from Redis Cloud

### `redis.tf` - Redis Cloud Resources (70 lines)
Creates the Redis Cloud side:
- Provider configuration
- Payment method lookup
- Redis Cloud subscription
- 1GB database with RedisJSON module
- VPC peering initiation to AWS

### `variables.tf` - Configuration (15 lines)
Only 4 variables needed:
- Redis Cloud API credentials (2)
- AWS Account ID
- Credit card last 4 digits

### `outputs.tf` - Connection Info (50 lines)
All the information you need to connect:
- VPC details
- Redis endpoints (public + private)
- Password
- Ready-to-use redis-cli command

---

## Connecting to Redis

### From AWS EC2 Instance (in same VPC)

```bash
# Use private endpoint for best performance
redis-cli -h <private-host> -p <port> -a '<password>'

# Test connection
redis-cli -h <private-host> -p <port> -a '<password>' PING
# Returns: PONG
```

### From Anywhere (public endpoint)

```bash
redis-cli -h <public-host> -p <port> -a '<password>'
```

### Get connection details

```bash
terraform output -raw redis_cli_command
```

---

## What's Hardcoded?

All values are set to sensible defaults. To change them, edit the `.tf` files:

| Setting | Hardcoded Value | File to Edit |
|---------|----------------|--------------|
| AWS Region | us-west-2 | `redis.tf`, `aws.tf` |
| VPC CIDR | 10.0.0.0/16 | `aws.tf` |
| Public Subnet 1 | 10.0.1.0/24 (us-west-2a) | `aws.tf` |
| Public Subnet 2 | 10.0.2.0/24 (us-west-2b) | `aws.tf` |
| Redis Cloud CIDR | 10.42.0.0/24 | `redis.tf` |
| Database Size | 1GB | `redis.tf` |
| Throughput | 1000 ops/sec | `redis.tf` |
| Replication | Enabled | `redis.tf` |
| Persistence | AOF every 1 second | `redis.tf` |
| Modules | RedisJSON | `redis.tf` |

---

## Customizing

Want to change something? It's easy - just edit the files:

### Change Database Size

Edit `redis.tf`, change both `dataset_size_in_gb` values:

```hcl
creation_plan {
  dataset_size_in_gb = 5  # Change from 1 to 5
  # ...
}

resource "rediscloud_subscription_database" "database" {
  dataset_size_in_gb = 5  # Change from 1 to 5
  # ...
}
```

### Add More Redis Modules

Edit `redis.tf`, add to modules list:

```hcl
modules {
  name = "RedisJSON"
}
modules {
  name = "RediSearch"
}
modules {
  name = "RedisTimeSeries"
}
```

### Change AWS Region

Edit both `redis.tf` and `aws.tf`, replace `us-west-2` with your region:

```hcl
# redis.tf
provider "aws" {
  region = "us-east-1"  # Change here
}

# aws.tf
availability_zone = "us-east-1a"  # Change here
availability_zone = "us-east-1b"  # And here
```

---

## Cost Estimate

**Redis Cloud:**
- 1GB database with replication: ~$15-25/month
- Varies by region and plan

**AWS:**
- VPC, subnets, IGW, route tables: Free
- VPC Peering: Free
- Data transfer: ~$0.01/GB

**Total**: ~$15-30/month depending on usage

---

## Cleanup

Remove everything:

```bash
terraform destroy
```

This deletes:
- AWS VPC and all networking
- Redis Cloud subscription and database
- VPC peering connection

---

## Troubleshooting

### "Subscription creation timeout"
- Redis Cloud API can be slow on first deployment
- Run `terraform refresh` to sync state
- Retry `terraform apply`

### "VPC Peering failed"
- Verify `aws_account_id` is correct (12 digits)
- Check AWS credentials are configured (`aws configure`)

### "Payment method not found"
- Verify `credit_card_last_four` matches card on file in Redis Cloud
- Check card type is "Visa" (or edit `redis.tf` for other types)

### Can't connect to Redis
- Check VPC peering status: `aws ec2 describe-vpc-peering-connections`
- Verify route table has Redis Cloud route: `aws ec2 describe-route-tables`
- Use `terraform output` to get correct endpoints

---

## Next Steps

### Deploy an Application

Launch an EC2 instance in one of the public subnets:

```bash
# Get VPC and subnet IDs
terraform output vpc_id
# Then launch EC2 in that VPC
```

### Scale Up

Need more capacity? Edit `redis.tf`:

```hcl
dataset_size_in_gb = 5
throughput_measurement_value = 5000
```

Then run:
```bash
terraform apply -target="rediscloud_subscription_database.database"
```

### Use the Full Version

Ready for production? Check out [`../redis-cloud-plus-aws-vpc-with-ec2/`](../redis-cloud-plus-aws-vpc-with-ec2/)

Features in the full version:
- Modular architecture for reusability
- EC2 testing instance with Redis CLI
- Prometheus + Grafana monitoring
- Multiple databases and subscriptions
- Private subnets
- Full variable configuration
- All optional Redis Cloud features

---

## Comparison: Simple vs Full Version

| Feature | Simple | Full |
|---------|--------|------|
| **Files** | 4 files | 40+ files (modules) |
| **Configuration** | Hardcoded in .tf files | Variables in tfvars |
| **Complexity** | Minimal | Production-ready |
| **Learning Curve** | 5 minutes | 30 minutes |
| **Use Case** | Learning, PoC | Production, scaling |
| **EC2 Instance** | ❌ No | ✅ Optional |
| **Monitoring** | ❌ No | ✅ Prometheus + Grafana |
| **Modules** | ❌ No | ✅ Yes (reusable) |
| **Private Subnets** | ❌ No | ✅ Yes |
| **Customization** | Edit .tf files | Edit tfvars |
| **Multiple DBs** | Hard to add | Easy to add |

---

## Support

- **Redis Cloud Docs**: https://docs.redis.com/
- **Terraform Provider**: https://registry.terraform.io/providers/RedisLabs/rediscloud/
- **AWS VPC Docs**: https://docs.aws.amazon.com/vpc/

---

## License

This is example code for learning and proof-of-concept purposes.
