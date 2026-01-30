# =============================================================================
# REDIS ECS TESTING MODULE OUTPUTS
# =============================================================================

output "cluster_names" {
  description = "Map of region to ECS cluster name"
  value = {
    for region, cluster in aws_ecs_cluster.redis_test :
    region => cluster.name
  }
}

output "cluster_arns" {
  description = "Map of region to ECS cluster ARN"
  value = {
    for region, cluster in aws_ecs_cluster.redis_test :
    region => cluster.arn
  }
}

output "service_names" {
  description = "Map of region to ECS service name"
  value = {
    for region, service in aws_ecs_service.redis_test :
    region => service.name
  }
}

output "task_definition_arns" {
  description = "Map of region to task definition ARN"
  value = {
    for region, task_def in aws_ecs_task_definition.redis_client :
    region => task_def.arn
  }
}

output "log_group_names" {
  description = "Map of region to CloudWatch Log Group name"
  value = {
    for region, log_group in aws_cloudwatch_log_group.redis_test :
    region => log_group.name
  }
}

output "redis_endpoints_configured" {
  description = "Redis endpoints that tasks are configured to connect to"
  value       = var.redis_endpoints
}

# =============================================================================
# HELPFUL COMMANDS
# =============================================================================

output "scale_up_commands" {
  description = "Commands to scale up ECS services for testing (map of region to command)"
  value = {
    for region, cluster in aws_ecs_cluster.redis_test :
    region => "aws ecs update-service --cluster ${cluster.name} --service ${aws_ecs_service.redis_test[region].name} --desired-count 10 --region ${region}"
  }
}

output "scale_down_commands" {
  description = "Commands to scale down ECS services to 0 (stop incurring costs)"
  value = {
    for region, cluster in aws_ecs_cluster.redis_test :
    region => "aws ecs update-service --cluster ${cluster.name} --service ${aws_ecs_service.redis_test[region].name} --desired-count 0 --region ${region}"
  }
}

output "view_logs_commands" {
  description = "Commands to view CloudWatch logs for each region"
  value = {
    for region, log_group in aws_cloudwatch_log_group.redis_test :
    region => "aws logs tail ${log_group.name} --follow --region ${region}"
  }
}

output "exec_into_task_commands" {
  description = "Commands to exec into running tasks (if enable_ecs_exec = true)"
  value = var.enable_ecs_exec ? {
    for region, cluster in aws_ecs_cluster.redis_test :
    region => "aws ecs execute-command --cluster ${cluster.name} --task <TASK_ID> --container redis-client --interactive --command '/bin/sh' --region ${region}"
  } : null
}

# =============================================================================
# COST INFORMATION
# =============================================================================

output "cost_info" {
  description = "Estimated hourly cost when tasks are running"
  value = {
    cost_per_task_per_hour = format("$%.4f", (var.task_cpu / 1024) * 0.04048 + (var.task_memory / 1024) * 0.004445)
    total_regions          = length(var.redis_endpoints)
    cost_when_scaled_to_0  = "$0.00"
    note                   = "Costs only incur when desired_count > 0"
  }
}

# =============================================================================
# QUICK START GUIDE
# =============================================================================

output "quick_start" {
  description = "Quick start guide for using the ECS testing infrastructure"
  value = <<-EOT

    ╔══════════════════════════════════════════════════════════════════╗
    ║         Redis ECS Testing Infrastructure - Quick Start          ║
    ╚══════════════════════════════════════════════════════════════════╝

    📊 Status:
       - ECS Clusters: ${length(aws_ecs_cluster.redis_test)} created
       - Services: ${length(aws_ecs_service.redis_test)} (scaled to ${var.default_task_count})
       - Cost: ${var.default_task_count == 0 ? "$0/hour (scaled to 0)" : format("~$%.2f/hour", var.default_task_count * length(var.redis_endpoints) * ((var.task_cpu / 1024) * 0.04048 + (var.task_memory / 1024) * 0.004445))}

    🚀 Scale Up for Testing:
       ${join("\n       ", [for region, cmd in {
  for region, cluster in aws_ecs_cluster.redis_test :
  region => "aws ecs update-service --cluster ${cluster.name} --service ${aws_ecs_service.redis_test[region].name} --desired-count 10 --region ${region}"
  } : cmd])}

    📉 Scale Down (Stop Costs):
       ${join("\n       ", [for region, cmd in {
  for region, cluster in aws_ecs_cluster.redis_test :
  region => "aws ecs update-service --cluster ${cluster.name} --service ${aws_ecs_service.redis_test[region].name} --desired-count 0 --region ${region}"
} : cmd])}

    📋 View Logs:
       ${join("\n       ", [for region, log_group in aws_cloudwatch_log_group.redis_test : "aws logs tail ${log_group.name} --follow --region ${region}"])}

    ℹ️  Note: Tasks are configured to connect to Redis endpoints:
       ${join("\n       ", [for region, endpoint in var.redis_endpoints : "${region}: ${endpoint.host}:${endpoint.port}"])}

  EOT
}
