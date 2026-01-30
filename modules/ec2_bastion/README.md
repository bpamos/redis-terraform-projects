# EC2 Bastion Module

Reusable Terraform module for deploying an EC2 bastion/testing instance with Redis tools, kubectl, AWS CLI, and other utilities.

## Features

- **Redis Testing Tools**: Includes `redis-cli`, `memtier_benchmark` for Redis connectivity testing and benchmarking
- **Kubernetes Management**: Optional `kubectl` installation with automatic EKS cluster configuration
- **AWS Management**: Optional AWS CLI v2 installation with region configuration
- **Container Support**: Optional Docker installation for container operations
- **Pre-configured Endpoints**: Support for multiple Redis endpoints with automatic testing
- **Test Scripts**: Ready-to-use scripts for connection testing and benchmarking
- **Security**: Optional security group creation or bring your own
- **Flexible Networking**: Support for public or private deployments

## Use Cases

1. **Bastion/Jump Host**: SSH access to private resources in VPC
2. **Redis Testing**: Connect to and test Redis databases with redis-cli and memtier_benchmark
3. **Troubleshooting**: Debug Kubernetes deployments with kubectl
4. **Admin Tasks**: Database migrations, manual operations, cluster management
5. **Monitoring**: Future support for Grafana and Prometheus installations

## Prerequisites

- AWS account with appropriate permissions
- VPC with at least one subnet
- SSH key pair in the target AWS region
- (Optional) EKS cluster for kubectl configuration

## Usage

### Basic Usage - Redis Testing Only

```hcl
module "bastion" {
  source = "../../modules/ec2_bastion"

  name_prefix = "myproject"
  owner       = "myteam"
  project     = "redis-enterprise"

  # Networking
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
  key_name  = "my-ssh-key"

  # Redis endpoints for testing
  redis_endpoints = {
    demo = {
      endpoint = "demo.redis-enterprise.svc.cluster.local:12000"
      password = "mypassword"
    }
    prod = {
      endpoint = "prod-redis.example.com:12000"
      password = "prodpassword"
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Usage - Full Tooling with EKS

```hcl
module "bastion" {
  source = "../../modules/ec2_bastion"

  name_prefix  = "myproject"
  owner        = "myteam"
  project      = "redis-enterprise-eks"
  instance_type = "t3.medium"

  # Networking
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
  key_name  = "my-ssh-key"

  # Install additional tools
  install_kubectl = true
  install_aws_cli = true
  install_docker  = true

  # EKS cluster configuration
  eks_cluster_name = "my-eks-cluster"
  aws_region       = "us-west-2"

  # Redis endpoints
  redis_endpoints = {
    demo = {
      endpoint = "demo-redis.us-west-2.elb.amazonaws.com:12000"
      password = "admin"
    }
  }

  tags = {
    Environment = "production"
  }
}

# Output connection info
output "bastion_ssh" {
  value = module.bastion.ssh_command
}

output "bastion_ip" {
  value = module.bastion.public_ip
}
```

### Using Custom Security Group

```hcl
resource "aws_security_group" "custom_bastion" {
  name_prefix = "custom-bastion-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Your office IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "bastion" {
  source = "../../modules/ec2_bastion"

  name_prefix = "myproject"
  owner       = "myteam"
  project     = "redis"

  # Use custom security group
  security_group_id = aws_security_group.custom_bastion.id
  subnet_id         = module.vpc.public_subnets[0]
  key_name          = "my-ssh-key"
}
```

### Private Subnet Deployment

```hcl
module "bastion" {
  source = "../../modules/ec2_bastion"

  name_prefix = "myproject"
  owner       = "myteam"
  project     = "redis"

  # Deploy in private subnet without public IP
  subnet_id           = module.vpc.private_subnets[0]
  associate_public_ip = false
  key_name            = "my-ssh-key"
  vpc_id              = module.vpc.vpc_id

  # Restrict SSH to VPC CIDR only
  ssh_cidr_blocks = [module.vpc.vpc_cidr_block]
}
```

## Connecting to the Bastion

After deployment, connect via SSH:

```bash
# Get SSH command from output
terraform output bastion_ssh

# Or manually
ssh -i ~/.ssh/my-ssh-key.pem ubuntu@<public_ip>
```

## Using the Bastion

### Test Redis Connection

```bash
# Using pre-configured endpoint
./test-redis-connection.sh demo.redis.com:12000 mypassword

# Basic test (no password)
./test-redis-connection.sh 10.0.1.10:12000
```

### Run Redis Benchmark

```bash
# 60 second benchmark with password
./run-memtier-benchmark.sh demo.redis.com:12000 mypassword 60

# 120 second benchmark without password
./run-memtier-benchmark.sh 10.0.1.10:12000 "" 120
```

### Use Redis CLI Directly

```bash
# Connect to Redis
redis-cli -h demo.redis.com -p 12000 -a mypassword

# Test commands
redis-cli -h 10.0.1.10 -p 12000 SET mykey "Hello World"
redis-cli -h 10.0.1.10 -p 12000 GET mykey
```

### Configure kubectl for EKS

If `install_kubectl=true` and `eks_cluster_name` is provided:

```bash
# Configure kubectl (requires AWS credentials)
./configure-kubectl.sh

# Verify cluster access
kubectl get nodes
kubectl get pods -n redis-enterprise
```

### Check Installation Logs

```bash
# View setup logs
tail -f /var/log/user-data.log

# Check pre-configured endpoints
cat redis-endpoints.json | jq '.'
```

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| owner | Owner tag for resources | string | - | yes |
| project | Project tag for resources | string | - | yes |
| subnet_id | Subnet ID to launch instance into | string | - | yes |
| key_name | SSH key pair name | string | - | yes |
| instance_type | EC2 instance type | string | t3.small | no |
| vpc_id | VPC ID (required if creating security group) | string | "" | no |
| security_group_id | Existing security group ID | string | "" | no |
| ssh_cidr_blocks | CIDR blocks for SSH access | list(string) | ["0.0.0.0/0"] | no |
| associate_public_ip | Associate public IP address | bool | true | no |
| redis_endpoints | Map of Redis endpoints | map(object) | {} | no |
| install_kubectl | Install kubectl | bool | false | no |
| install_aws_cli | Install AWS CLI v2 | bool | false | no |
| install_docker | Install Docker | bool | false | no |
| eks_cluster_name | EKS cluster name for kubectl config | string | "" | no |
| aws_region | AWS region for EKS/CLI config | string | "" | no |
| tags | Additional resource tags | map(string) | {} | no |

## Module Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| public_ip | Public IP address |
| private_ip | Private IP address |
| public_dns | Public DNS name |
| security_group_id | Security group ID |
| ssh_command | SSH connection command |
| connection_info | Complete connection information |
| available_tools | List of installed tools |
| test_scripts_info | Information about test scripts |
| usage_examples | Example commands |

## Security Considerations

1. **SSH Access**: By default, SSH is open to 0.0.0.0/0. Restrict `ssh_cidr_blocks` to your IP range in production
2. **Secrets Management**: Redis passwords are marked as sensitive. Consider using AWS Secrets Manager for production
3. **Public IP**: Set `associate_public_ip=false` and use VPN/bastion pattern for private deployments
4. **Key Management**: Store SSH private keys securely, never commit to version control
5. **IAM Permissions**: If using AWS CLI/kubectl, attach appropriate IAM role to instance

## Troubleshooting

### Instance not accessible via SSH

- Check security group allows inbound port 22 from your IP
- Verify subnet has internet gateway (if using public IP)
- Ensure key pair name matches the key you're using

### Redis tools not installed

- SSH to instance and check `/var/log/user-data.log`
- Verify internet connectivity from instance
- Re-run setup manually: `sudo /var/lib/cloud/instance/scripts/part-001`

### kubectl not working

- Ensure `install_kubectl=true` was set
- Configure AWS credentials: `aws configure`
- Run configure script: `./configure-kubectl.sh`
- Verify IAM permissions for EKS cluster access

## Future Enhancements

- [ ] Grafana installation option
- [ ] Prometheus installation option
- [ ] RIOT (Redis Input/Output Tools) installation
- [ ] Automated Redis cluster discovery
- [ ] CloudWatch logs integration
- [ ] Systems Manager Session Manager support

## License

This module is part of the Redis Terraform Projects repository.

## Authors

Created and maintained by the Redis Enterprise team.
