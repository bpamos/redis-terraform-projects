output "riotx_replication_triggered" {
  description = "Indicates that RIOT-X live replication was successfully started"
  value       = null_resource.start_riotx_replication.id != null
}

output "replication_config" {
  description = "Complete RIOT-X replication configuration details"
  value = {
    source_endpoint    = "redis://${var.elasticache_endpoint}:6379"
    target_endpoint    = "redis://${var.rediscloud_private_endpoint}"
    replication_mode   = var.replication_mode
    metrics_enabled    = var.enable_metrics
    metrics_port       = var.metrics_port
    log_keys_enabled   = var.log_keys
    script_location    = "/home/ubuntu/start_riotx.sh"
    log_file_location  = "/home/ubuntu/riotx.log"
  }
}

output "replicating_from" {
  description = "Source Redis (ElastiCache) endpoint used in the replication"
  value       = var.elasticache_endpoint
}

output "replicating_to" {
  description = "Target Redis Cloud endpoint used in the replication"
  value       = var.rediscloud_private_endpoint
}

output "metrics_url" {
  description = "URL to access RIOT-X metrics (if enabled)"
  value       = var.enable_metrics ? "http://${var.ec2_public_ip}:${var.metrics_port}/metrics" : "Metrics disabled"
}

output "monitoring_commands" {
  description = "Useful commands for monitoring RIOT-X replication"
  value = {
    view_logs        = "ssh ubuntu@${var.ec2_public_ip} 'tail -f /home/ubuntu/riotx.log'"
    check_status     = "ssh ubuntu@${var.ec2_public_ip} 'ps aux | grep riotx'"
    restart_script   = "ssh ubuntu@${var.ec2_public_ip} 'nohup /home/ubuntu/start_riotx.sh > /home/ubuntu/riotx_restart.log 2>&1 &'"
    view_startup_log = "ssh ubuntu@${var.ec2_public_ip} 'cat /home/ubuntu/riotx_startup.log'"
  }
}
