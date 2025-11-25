# =============================================================================
# TEST NODE MODULE OUTPUTS
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.test.id
}

output "public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.test.public_ip
}

output "public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_instance.test.public_dns
}

output "private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.test.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.test.public_ip}"
}

output "test_scripts_info" {
  description = "Information about test scripts available on the instance"
  value = {
    connection_test = "./test-redis-connection.sh <endpoint> <password>"
    benchmark       = "./run-memtier-benchmark.sh <endpoint> <password> [duration]"
    logs            = "/var/log/user-data.log"
  }
}

output "available_tools" {
  description = "Testing tools installed on the instance"
  value = {
    redis_cli         = "Redis command-line client"
    memtier_benchmark = "Redis load generation and benchmarking tool"
  }
}
