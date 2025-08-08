output "instance_ids" {
  description = "List of Redis Enterprise node instance IDs"
  value       = aws_instance.redis_enterprise_nodes[*].id
}

output "public_ips" {
  description = "List of public IP addresses for Redis Enterprise nodes"
  value       = aws_instance.redis_enterprise_nodes[*].public_ip
}

output "private_ips" {
  description = "List of private IP addresses for Redis Enterprise nodes"
  value       = aws_instance.redis_enterprise_nodes[*].private_ip
}

output "public_dns" {
  description = "List of public DNS names for Redis Enterprise nodes"
  value       = aws_instance.redis_enterprise_nodes[*].public_dns
}

output "private_dns" {
  description = "List of private DNS names for Redis Enterprise nodes"
  value       = aws_instance.redis_enterprise_nodes[*].private_dns
}

output "data_volume_ids" {
  description = "List of data EBS volume IDs"
  value       = aws_ebs_volume.redis_data[*].id
}

output "persistent_volume_ids" {
  description = "List of persistent EBS volume IDs"
  value       = aws_ebs_volume.redis_persistent[*].id
}

output "primary_node_ip" {
  description = "IP address of the primary Redis Enterprise node (node 1)"
  value       = aws_instance.redis_enterprise_nodes[0].public_ip
}

output "primary_node_private_ip" {
  description = "Private IP address of the primary Redis Enterprise node"
  value       = aws_instance.redis_enterprise_nodes[0].private_ip
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "sample_database_endpoint" {
  description = "FQDN endpoint for the sample Redis database (external)"
  value       = var.create_sample_database ? "${var.sample_db_name}-${var.sample_db_port}.${local.cluster_full_fqdn}:${var.sample_db_port}" : null
}

output "sample_database_endpoint_private" {
  description = "Private FQDN endpoint for the sample Redis database (internal)"
  value       = var.create_sample_database ? "${var.sample_db_name}-${var.sample_db_port}-internal.${local.cluster_full_fqdn}:${var.sample_db_port}" : null
}

output "sample_database_info" {
  description = "Information about the created sample database"
  value = var.create_sample_database ? {
    name              = var.sample_db_name
    port              = var.sample_db_port
    memory            = "${var.sample_db_memory}MB"
    endpoint_external = "${var.sample_db_name}-${var.sample_db_port}.${local.cluster_full_fqdn}:${var.sample_db_port}"
    endpoint_internal = "${var.sample_db_name}-${var.sample_db_port}-internal.${local.cluster_full_fqdn}:${var.sample_db_port}"
  } : null
}