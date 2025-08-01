# ElastiCache-Only Terraform Project

This project creates AWS ElastiCache Redis infrastructure with supporting VPC and security groups.

## What This Creates

- **VPC**: Virtual Private Cloud with public/private subnets
- **Security Groups**: Proper security group configuration for ElastiCache
- **ElastiCache Redis**: Standalone Redis with keyspace notifications enabled
- **High Availability**: Multi-AZ deployment with read replicas

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- An AWS account with ElastiCache creation permissions

## Quick Start

1. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get connection details**:
   ```bash
   terraform output elasticache_primary_endpoint
   terraform output redis_cli_command
   ```

## Configuration

### Required Variables

- `name_prefix`: Unique prefix for all resources
- `owner`: Your name or team identifier

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `node_type`: ElastiCache instance type (default: cache.t3.micro)
- `standalone_replicas`: Number of read replicas (default: 1)
- `allow_ssh_from`: SSH access CIDRs (default: 0.0.0.0/0)

## Outputs

Key outputs for connecting to your Redis:

- `elasticache_primary_endpoint`: Primary endpoint for writes
- `elasticache_reader_endpoint`: Reader endpoint for reads
- `redis_cli_command`: Ready-to-use Redis CLI command
- `redis_connection_info`: Complete connection details

## Connecting to ElastiCache

### Using Redis CLI

```bash
# Get the connection command
terraform output -raw redis_cli_command

# Example output:
# redis-cli -h your-cluster.cache.amazonaws.com -p 6379
```

### From Application Code

```python
import redis

# Get endpoint from terraform output
endpoint = "your-cluster.cache.amazonaws.com"

# Connect (no auth required by default)
r = redis.Redis(host=endpoint, port=6379, decode_responses=True)
r.ping()
```

### Connection Details

- **Port**: 6379 (standard Redis port)
- **Authentication**: None (default ElastiCache configuration)
- **SSL**: Not enabled (can be configured if needed)
- **Network**: Private subnets only (secure by default)

## Features

### Keyspace Notifications Enabled

This ElastiCache deployment has keyspace notifications enabled, which is required for:
- Live replication with RIOT-X
- Event-driven applications
- Cache invalidation patterns

### High Availability

- **Multi-AZ**: Deployed across multiple availability zones
- **Read Replicas**: Configurable number of read replicas
- **Automatic Failover**: Built-in failover capabilities

## Monitoring

### CloudWatch Metrics

ElastiCache automatically provides metrics for:
- CPU utilization
- Memory usage
- Network I/O
- Cache hit/miss ratios
- Connection counts

### Access Logs

```bash
# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/elasticache
```

## Cost Optimization

- Start with `cache.t3.micro` for development
- Use `cache.t3.small` or larger for production
- Monitor CPU and memory usage to right-size instances
- Consider reserved instances for long-term workloads

## Security Best Practices

1. **Network Security**: ElastiCache is deployed in private subnets
2. **Access Control**: Use security groups to limit access
3. **Encryption**: Consider enabling encryption in transit and at rest
4. **VPC**: Isolated within your VPC, not publicly accessible

## Scaling

### Vertical Scaling (Instance Size)
```bash
# Update node_type in terraform.tfvars
node_type = "cache.t3.medium"  # Scale up

# Apply changes
terraform apply
```

### Horizontal Scaling (Read Replicas)
```bash
# Update replica count in terraform.tfvars
standalone_replicas = 2  # Add more read replicas

# Apply changes
terraform apply
```

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Check security group rules
2. **Memory pressure**: Monitor CloudWatch metrics and scale up
3. **High CPU**: Consider scaling up instance type
4. **Network issues**: Verify VPC and subnet configuration

### Useful Commands

```bash
# Check ElastiCache status
aws elasticache describe-replication-groups

# View security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*elasticache*"

# Monitor metrics
aws cloudwatch get-metric-statistics --namespace AWS/ElastiCache
```

## Integration with Other Projects

This ElastiCache can be used with other projects:

### With RIOT Tooling
```hcl
# Reference this ElastiCache in riot-tooling-only project
elasticache_endpoint = data.terraform_remote_state.elasticache.outputs.elasticache_primary_endpoint
```

### With Applications
Use the outputs to configure your applications to connect to this ElastiCache instance.

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Support

- AWS ElastiCache Documentation: https://docs.aws.amazon.com/elasticache/
- Redis Documentation: https://redis.io/documentation