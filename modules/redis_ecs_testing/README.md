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

### With Redis Authentication

```hcl
module "ecs_testing" {
  source = "../../modules/redis_ecs_testing"

  # ... basic config ...

  redis_password = var.redis_password  # From your tfvars
}
```

### Custom Application with Environment Variables

```hcl
module "ecs_testing" {
  source = "../../modules/redis_ecs_testing"

  # ... basic config ...

  test_container_image = "<ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/my-redis-app:latest"

  app_environment = {
    OPERATIONS_PER_SECOND = "500"
    KEY_PREFIX            = "myapp"
    REPORT_INTERVAL       = "30"
    MY_CUSTOM_VAR         = "custom_value"
  }
}
```

## Example Application

This module includes a **ready-to-use Python application** in `example_app/` that demonstrates how to build custom test applications.

### Quick Start with Example App

1. **Build the Docker image:**
   ```bash
   cd modules/redis_ecs_testing/example_app
   docker build -t redis-test-app .
   ```

2. **Test locally (optional):**
   ```bash
   docker run -e REDIS_HOST=localhost -e REDIS_PORT=6379 redis-test-app
   ```

3. **Push to ECR:**
   ```bash
   # Create repository (one-time)
   aws ecr create-repository --repository-name redis-test-app --region us-west-2

   # Login and push
   aws ecr get-login-password --region us-west-2 | \
     docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com

   docker tag redis-test-app:latest <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/redis-test-app:latest
   docker push <ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/redis-test-app:latest
   ```

4. **Use in Terraform:**
   ```hcl
   module "ecs_testing" {
     source = "../../modules/redis_ecs_testing"

     redis_endpoints = {
       us-west-2 = { host = "my-redis.example.com", port = 12000 }
     }

     vpc_config = {
       us-west-2 = { vpc_id = "vpc-xxx", subnet_ids = ["subnet-aaa"] }
     }

     cluster_prefix       = "myapp-test"
     test_container_image = "<ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/redis-test-app:latest"
     redis_password       = var.redis_password  # Optional

     app_environment = {
       OPERATIONS_PER_SECOND = "100"
       KEY_PREFIX            = "myapp"
     }
   }
   ```

### Creating Your Own Application

The example app (`example_app/app.py`) is designed as a template. To create your own:

1. **Copy the example:**
   ```bash
   cp -r modules/redis_ecs_testing/example_app my-app
   ```

2. **Modify `app.py`** - Replace the example operations with your logic:
   ```python
   def do_write(self):
       # Your write logic here
       self.client.hset("user:123", mapping={"name": "John", "visits": 1})

   def do_read(self):
       # Your read logic here
       return self.client.hgetall("user:123")
   ```

3. **Environment variables available to your app:**

   | Variable | Source | Description |
   |----------|--------|-------------|
   | `REDIS_HOST` | Module | Redis endpoint hostname |
   | `REDIS_PORT` | Module | Redis endpoint port |
   | `REDIS_PASSWORD` | Module | Redis AUTH password |
   | `REDIS_REGION` | Module | AWS region |
   | `TEST_MODE` | Module | ping/read/write/mixed |
   | Custom vars | `app_environment` | Your custom variables |

4. **Build and deploy** your modified image to ECR

### Example App Features

The included example application supports:

- **Multiple test modes:** ping, read, write, mixed, complex
- **Configurable throughput:** Set `OPERATIONS_PER_SECOND`
- **Pipeline operations:** Demonstrates efficient batching
- **Statistics reporting:** Logs ops/sec to CloudWatch
- **Graceful shutdown:** Handles SIGTERM from ECS
- **Error handling:** Backs off on connection errors

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| redis_endpoints | Map of region to Redis endpoint | map(object) | - | yes |
| vpc_config | VPC configuration per region | map(object) | - | yes |
| cluster_prefix | Prefix for resource names | string | - | yes |
| redis_password | Redis AUTH password | string | null | no |
| app_environment | Custom env vars for containers | map(string) | {} | no |
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
- VPC must have public subnets with Internet Gateway for pulling Docker images and accessing CloudWatch
- Tasks are assigned public IPs automatically for AWS service access (CloudWatch Logs, ECR)

## License

This module is part of the Redis Terraform Projects repository.
