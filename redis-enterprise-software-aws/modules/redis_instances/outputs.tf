# =============================================================================
# REDIS INSTANCES MODULE OUTPUTS
# =============================================================================

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.redis_enterprise_nodes[*].id
}

output "public_ips" {
  description = "List of public IP addresses (EIPs when enabled, otherwise instance public IPs)"
  value       = var.use_elastic_ips ? aws_eip.redis_enterprise_eips[*].public_ip : aws_instance.redis_enterprise_nodes[*].public_ip
}

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.redis_enterprise_nodes[*].private_ip
}

output "public_dns" {
  description = "List of public DNS names"
  value       = aws_instance.redis_enterprise_nodes[*].public_dns
}

output "private_dns" {
  description = "List of private DNS names"
  value       = aws_instance.redis_enterprise_nodes[*].private_dns
}

output "availability_zones" {
  description = "List of availability zones where instances are placed"
  value       = aws_instance.redis_enterprise_nodes[*].availability_zone
}

output "platform_config" {
  description = "Platform configuration including AMI and user info"
  value       = local.selected_config
}

output "selected_ami_id" {
  description = "Selected AMI ID for the platform"
  value       = local.selected_config.ami_id
}

output "instance_info" {
  description = "Comprehensive instance information"
  value = {
    for i, instance in aws_instance.redis_enterprise_nodes : 
    "node-${i + 1}" => {
      id                = instance.id
      public_ip         = var.use_elastic_ips ? aws_eip.redis_enterprise_eips[i].public_ip : instance.public_ip
      private_ip        = instance.private_ip
      public_dns        = instance.public_dns
      private_dns       = instance.private_dns
      availability_zone = instance.availability_zone
      instance_type     = instance.instance_type
      role             = i == 0 ? "primary" : "replica"
      node_index       = i
      eip_enabled      = var.use_elastic_ips
      eip_allocation_id = var.use_elastic_ips ? aws_eip.redis_enterprise_eips[i].allocation_id : null
    }
  }
}