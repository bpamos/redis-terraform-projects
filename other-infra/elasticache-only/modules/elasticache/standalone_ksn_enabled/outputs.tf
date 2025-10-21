output "primary_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "replication_group_id" {
  value = aws_elasticache_replication_group.this.id
}

output "parameter_group_name" {
  value = aws_elasticache_parameter_group.this.name
}
