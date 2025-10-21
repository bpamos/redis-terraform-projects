# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# =============================================================================
# RIOT EC2 OUTPUTS
# =============================================================================

output "riot_ec2_public_ip" {
  description = "Public IP address of the RIOT EC2 instance"
  value       = module.ec2_riot.public_ip
}

output "riot_ec2_private_ip" {
  description = "Private IP address of the RIOT EC2 instance"
  value       = module.ec2_riot.private_ip
}

output "riot_ec2_instance_id" {
  description = "Instance ID of the RIOT EC2 instance"
  value       = module.ec2_riot.instance_id
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "ssh_command" {
  description = "SSH command to connect to RIOT instance"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.ec2_riot.public_ip}"
}

output "redis_oss_connection" {
  description = "Connection information for local Redis OSS"
  value = {
    host = module.ec2_riot.private_ip
    port = "6379"
    auth = "none"
  }
}

# =============================================================================
# USEFUL COMMANDS
# =============================================================================

output "useful_commands" {
  description = "Useful commands for RIOT tooling"
  value = {
    check_riotx_version = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.ec2_riot.public_ip} 'riotx --version'"
    check_redis_oss = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.ec2_riot.public_ip} 'redis-cli ping'"
    list_redis_keys = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.ec2_riot.public_ip} 'redis-cli keys \"*\"'"
    generate_test_data = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.ec2_riot.public_ip} 'riotx generate --target redis://localhost:6379 --count 1000'"
  }
}

output "monitoring_urls" {
  description = "Monitoring and observability URLs (if enabled)"
  value = {
    grafana = "http://${module.ec2_riot.public_ip}:3000"
    prometheus = "http://${module.ec2_riot.public_ip}:9090"
    note = "These URLs are only accessible if observability is enabled in the RIOT module"
  }
}