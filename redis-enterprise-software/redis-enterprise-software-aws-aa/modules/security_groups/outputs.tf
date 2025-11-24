output "redis_enterprise_sg_id" {
  description = "Security group ID for Redis Enterprise cluster"
  value       = aws_security_group.redis_enterprise.id
}

output "test_node_sg_id" {
  description = "Security group ID for test node"
  value       = aws_security_group.test_node.id
}