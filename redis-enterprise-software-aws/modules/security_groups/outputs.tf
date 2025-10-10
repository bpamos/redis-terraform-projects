output "redis_enterprise_sg_id" {
  description = "Security group ID for Redis Enterprise cluster"
  value       = aws_security_group.redis_enterprise.id
}