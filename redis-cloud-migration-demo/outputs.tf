output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "route_table_id" {
  description = "Main route table ID for VPC peering configuration"
  value       = module.vpc.route_table_id
}

### Elasticache

### ElastiCache Standalone with KSN enabled

output "elasticache_standalone_ksn_primary_endpoint" {
  description = "Primary endpoint for ElastiCache standalone Redis with keyspace notifications enabled"
  value       = module.elasticache_standalone_ksn.primary_endpoint
}

output "elasticache_standalone_ksn_replication_group_id" {
  description = "Replication group ID for ElastiCache standalone Redis with KSN"
  value       = module.elasticache_standalone_ksn.replication_group_id
}

output "elasticache_standalone_ksn_parameter_group" {
  description = "Parameter group name for ElastiCache standalone Redis with KSN"
  value       = module.elasticache_standalone_ksn.parameter_group_name
}



### RIOT EC2

output "ec2_riot_instance_id" {
  description = "EC2 instance ID running RIOTX migration tools"
  value       = module.ec2_riot.instance_id
}

output "ec2_riot_public_ip" {
  description = "Public IP address of RIOTX EC2 instance for SSH access"
  value       = module.ec2_riot.public_ip
}

output "ec2_riot_public_dns" {
  description = "Public DNS name of RIOTX EC2 instance"
  value       = module.ec2_riot.public_dns
}

output "ec2_riot_riotx_ready_id" {
  description = "Indicates when the riotx binary is ready on the EC2 instance"
  value       = module.ec2_riot.riotx_ready_id
}

### EC2 Application

output "application_ec2_public_ip" {
  description = "Public IP address of demo application EC2 instance"
  value       = module.ec2_application.public_ip
}

output "application_ec2_private_ip" {
  description = "Private IP address of demo application EC2 instance"
  value       = module.ec2_application.private_ip
}

output "application_ec2_instance_id" {
  value = module.ec2_application.instance_id
}


### Redis Cloud

output "rediscloud_subscription_id" {
  value       = module.rediscloud.rediscloud_subscription_id
  description = "Redis Cloud subscription ID"
}

output "rediscloud_database_id" {
  value       = module.rediscloud.database_id
  description = "Redis Cloud database ID"
}

output "rediscloud_public_endpoint" {
  value       = module.rediscloud.database_public_endpoint
  description = "Public endpoint for Redis Cloud database"
}

output "rediscloud_private_endpoint" {
  value       = module.rediscloud.database_private_endpoint
  description = "Private endpoint for Redis Cloud database"
}

output "rediscloud_password" {
  value       = module.rediscloud.rediscloud_password
  description = "Password to access Redis Cloud database"
  sensitive   = true
}

### RIOTX replication

output "riotx_replication_status" {
  description = "Outputs status and endpoints used by the riotx_replication module."
  value = {
    triggered = module.riotx_replication.riotx_replication_triggered
    source    = module.riotx_replication.replicating_from
    target    = module.riotx_replication.replicating_to
  }
}

#### CUTOVER UI

output "cutover_ui_url" {
  description = "URL to access the Cutover UI"
  value       = module.cutover_ui.cutover_ui_url
}

#### APPLICATION URLS

output "redisarena_app_url" {
  description = "URL to access the RedisArena gaming application"
  value       = "http://${module.ec2_application.public_ip}:5000"
}

#### GRAFANA MONITORING

output "grafana_url" {
  description = "URL to access Grafana monitoring dashboard"
  value       = "http://${module.ec2_riot.public_ip}:3000"
}

output "grafana_credentials" {
  description = "Default Grafana login credentials"
  value = {
    username = "admin"
    password = "admin"
    note     = "Default credentials - change on first login"
  }
  sensitive = false
}

#### DEMO ACCESS INFORMATION

output "demo_access_info" {
  description = "Complete access information for the Redis migration demo"
  value = {
    # Web Applications
    cutover_ui_url       = module.cutover_ui.cutover_ui_url
    redisarena_app_url   = "http://${module.ec2_application.public_ip}:5000"
    grafana_url          = "http://${module.ec2_riot.public_ip}:3000"
    
    # Infrastructure IPs
    application_ip       = module.ec2_application.public_ip
    riot_ip             = module.ec2_riot.public_ip
    
    # Redis Endpoints
    redis_cloud_endpoint = module.rediscloud.database_public_endpoint
    elasticache_endpoint = module.elasticache_standalone_ksn.primary_endpoint
    
    # Access Info
    grafana_username     = "admin"
    grafana_password     = "admin"
    ssh_key_required     = "Use your private key for SSH access"
  }
}



