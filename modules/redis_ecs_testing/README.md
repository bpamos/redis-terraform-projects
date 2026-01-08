# Redis ECS Testing Infrastructure Module

Shared Terraform module for creating ECS-based testing infrastructure for Redis deployments. Supports load testing, application simulation, and continuous monitoring.

## Features

- ✅ **ECS Fargate clusters** in each Redis region
- ✅ **Auto-configured** to connect to Redis endpoints
- ✅ **Cost-efficient** - Scales to 0 when not testing (no cost)
- ✅ **Load testing** - Optional redis-benchmark tasks
- ✅ **CloudWatch integration** - Logs and Container Insights
- ✅ **ECS Exec** - Debug running containers
- ✅ **Multi-region** - Test all regions simultaneously

## Usage

This module is designed to be called from Redis deployment projects.

### Basic Example

```hcl
module "ecs_testing" {
  source = "../../modules/redis_ecs_testing"

  redis_endpoints = {
    us-west-2 = {
      host = "redis-12000.cluster.example.com"
      port = 12000
    }
    us-east-1 = {
      host = "redis-12000.cluster2.example.com"
      port = 12000
    }
  }

  vpc_config = {
    us-west-2 = {
      vpc_id     = "vpc-xxx"
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
    us-east-1 = {
      vpc_id     = "vpc-yyy"
      subnet_ids = ["subnet-ccc", "subnet-ddd"]
    }
  }

  cluster_prefix = "myapp-redis"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With Load Testing Enabled

```hcl
module "ecs_testing" {
  source = "../../modules/redis_ecs_testing"

  # ... basic config ...

  enable_load_testing    = true
  load_test_connections  = 100
  load_test_requests     = 1000000
}
```

### Custom Test Command

```hcl
module "ecs_testing" {
  source = "../../modules/redis_ecs_testing"

  # ... basic config ...

  custom_command = [
    "sh", "-c",
    "python3 /app/custom_test.py"
  ]

  test_container_image = "mycompany/redis-test-app:latest"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| redis_endpoints | Map of region to Redis endpoint | map(object) | - | yes |
| vpc_config | VPC configuration per region | map(object) | - | yes |
| cluster_prefix | Prefix for resource names | string | - | yes |
| task_cpu | CPU units for task | number | 256 | no |
| task_memory | Memory in MB | number | 512 | no |
| default_task_count | Initial task count | number | 0 | no |
| enable_load_testing | Enable redis-benchmark | bool | false | no |
| test_container_image | Docker image | string | redis:latest | no |
| tags | Additional tags | map(string) | {} | no |

See [variables.tf](./variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| cluster_names | ECS cluster names per region |
| service_names | ECS service names per region |
| scale_up_commands | Commands to start testing |
| scale_down_commands | Commands to stop tasks |
| view_logs_commands | Commands to view logs |
| quick_start | Quick start guide |

## Cost Model

**When scaled to 0 (default):** $0/hour
**Per task per hour:** ~$0.01 (256 CPU, 512 MB)
**Load testing (10 tasks, 1 hour):** ~$0.10

Example monthly costs:
- **Always on (1 task/region):** ~$15/month (2 regions)
- **Test 10 hours/month (10 tasks):** ~$2/month
- **Idle (scaled to 0):** $0/month

## Common Operations

### Scale Up for Testing

```bash
# Scale to 10 tasks in us-west-2
aws ecs update-service \
  --cluster myapp-redis-test-us-west-2 \
  --service redis-test-us-west-2 \
  --desired-count 10 \
  --region us-west-2
```

### View Logs

```bash
# Tail logs
aws logs tail /ecs/myapp-redis-test-us-west-2 --follow --region us-west-2

# Query logs (last hour)
aws logs filter-log-events \
  --log-group-name /ecs/myapp-redis-test-us-west-2 \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region us-west-2
```

### Exec Into Running Task

```bash
# List running tasks
aws ecs list-tasks \
  --cluster myapp-redis-test-us-west-2 \
  --service-name redis-test-us-west-2 \
  --region us-west-2

# Exec into task
aws ecs execute-command \
  --cluster myapp-redis-test-us-west-2 \
  --task <TASK_ID> \
  --container redis-client \
  --interactive \
  --command "/bin/sh" \
  --region us-west-2
```

### Scale Down (Stop Costs)

```bash
aws ecs update-service \
  --cluster myapp-redis-test-us-west-2 \
  --service redis-test-us-west-2 \
  --desired-count 0 \
  --region us-west-2
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│ Region: us-west-2                               │
│                                                  │
│  ┌──────────────────┐     ┌─────────────────┐  │
│  │ ECS Cluster      │     │ Redis CRDB      │  │
│  │  ┌────────────┐  │     │                 │  │
│  │  │ Task 1     │──┼────►│ Port: 12000     │  │
│  │  │ redis-cli  │  │     └─────────────────┘  │
│  │  └────────────┘  │                           │
│  │  ┌────────────┐  │     ┌─────────────────┐  │
│  │  │ Task 2     │──┼────►│ CloudWatch Logs │  │
│  │  │ redis-cli  │  │     │                 │  │
│  │  └────────────┘  │     └─────────────────┘  │
│  └──────────────────┘                           │
└─────────────────────────────────────────────────┘
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- Redis endpoints must be accessible from ECS tasks
- VPC must have private subnets with NAT Gateway for image pulls

## License

This module is part of the Redis Terraform Projects repository.
