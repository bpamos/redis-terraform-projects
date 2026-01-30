# =============================================================================
# REDIS ECS TESTING INFRASTRUCTURE
# =============================================================================
# Shared module for creating ECS-based testing infrastructure for Redis
# deployments. Supports load testing and application simulation.
# =============================================================================

locals {
  # Extract regions from redis_endpoints
  regions = keys(var.redis_endpoints)

  # Generate cluster names
  cluster_names = {
    for region in local.regions :
    region => "${var.cluster_prefix}-redis-test-${region}"
  }
}

# =============================================================================
# ECS CLUSTERS
# =============================================================================

# Create ECS cluster in each region
resource "aws_ecs_cluster" "redis_test" {
  for_each = var.vpc_config

  name = local.cluster_names[each.key]

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    {
      Name    = local.cluster_names[each.key]
      Purpose = "Redis Testing Infrastructure"
      Region  = each.key
    },
    var.tags
  )
}

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

resource "aws_cloudwatch_log_group" "redis_test" {
  for_each = var.redis_endpoints

  name              = "/ecs/${local.cluster_names[each.key]}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name   = "${local.cluster_names[each.key]}-logs"
      Region = each.key
    },
    var.tags
  )
}

# =============================================================================
# IAM ROLES
# =============================================================================

# Task execution role (for ECS to pull images, write logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role (for application to access AWS services if needed)
resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

resource "aws_security_group" "ecs_tasks" {
  for_each = var.vpc_config

  name_prefix = "${var.cluster_prefix}-ecs-tasks-${each.key}-"
  description = "Security group for ECS tasks testing Redis"
  vpc_id      = each.value.vpc_id

  # Allow all outbound traffic (needed to connect to Redis)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name   = "${var.cluster_prefix}-ecs-tasks-${each.key}"
      Region = each.key
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# ECS TASK DEFINITIONS
# =============================================================================

resource "aws_ecs_task_definition" "redis_client" {
  for_each = var.redis_endpoints

  family                   = "${var.cluster_prefix}-redis-client-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "redis-client"
    image = var.test_container_image

    environment = concat(
      [
        {
          name  = "REDIS_HOST"
          value = each.value.host
        },
        {
          name  = "REDIS_PORT"
          value = tostring(each.value.port)
        },
        {
          name  = "REDIS_REGION"
          value = each.key
        },
        {
          name  = "TEST_MODE"
          value = var.test_mode
        }
      ],
      var.redis_password != null ? [{ name = "REDIS_PASSWORD", value = var.redis_password }] : [],
      [for k, v in var.app_environment : { name = k, value = v }]
    )

    # Default command: continuous PING test
    command = var.custom_command != null ? var.custom_command : [
      "sh", "-c",
      "echo 'Starting Redis test client for ${each.key}'; while true; do redis-cli -h $REDIS_HOST -p $REDIS_PORT PING && echo 'PONG from ${each.key}' || echo 'Failed to connect to ${each.key}'; sleep ${var.test_interval_seconds}; done"
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.redis_test[each.key].name
        "awslogs-region"        = each.key
        "awslogs-stream-prefix" = "redis-client"
      }
    }

    healthCheck = {
      command = [
        "CMD-SHELL",
        "redis-cli -h $REDIS_HOST -p $REDIS_PORT PING || exit 1"
      ]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = merge(
    {
      Name   = "${var.cluster_prefix}-redis-client-${each.key}"
      Region = each.key
    },
    var.tags
  )
}

# =============================================================================
# ECS SERVICES
# =============================================================================

resource "aws_ecs_service" "redis_test" {
  for_each = var.redis_endpoints

  name            = "redis-test-${each.key}"
  cluster         = aws_ecs_cluster.redis_test[each.key].id
  task_definition = aws_ecs_task_definition.redis_client[each.key].arn
  desired_count   = var.default_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.vpc_config[each.key].subnet_ids
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = true # Required for public subnets to access AWS services (CloudWatch, ECR)
  }

  # Enable CloudWatch Container Insights
  enable_execute_command = var.enable_ecs_exec

  tags = merge(
    {
      Name   = "redis-test-${each.key}"
      Region = each.key
    },
    var.tags
  )

  # Ensure cluster and task definition are ready
  depends_on = [
    aws_ecs_cluster.redis_test,
    aws_ecs_task_definition.redis_client
  ]
}

# =============================================================================
# LOAD TESTING TASK DEFINITION (Optional)
# =============================================================================

resource "aws_ecs_task_definition" "redis_load_test" {
  count = var.enable_load_testing ? 1 : 0

  family                   = "${var.cluster_prefix}-redis-load-test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.load_test_task_cpu
  memory                   = var.load_test_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "redis-benchmark"
    image = "redis:latest"

    # Use redis-benchmark for load testing
    command = [
      "sh", "-c",
      "redis-benchmark -h ${var.redis_endpoints[local.regions[0]].host} -p ${var.redis_endpoints[local.regions[0]].port} -c ${var.load_test_connections} -n ${var.load_test_requests} -t get,set --csv"
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.redis_test[local.regions[0]].name
        "awslogs-region"        = local.regions[0]
        "awslogs-stream-prefix" = "redis-benchmark"
      }
    }
  }])

  tags = merge(
    {
      Name    = "${var.cluster_prefix}-redis-load-test"
      Purpose = "Load Testing"
    },
    var.tags
  )
}
