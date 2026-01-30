# =============================================================================
# EC2 BASTION MODULE OUTPUTS
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_instance.bastion.public_dns
}

output "private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "Security group ID used by the bastion instance"
  value       = var.security_group_id != "" ? var.security_group_id : aws_security_group.bastion[0].id
}

output "ssh_command" {
  description = "SSH command to connect to the bastion instance"
  value       = var.ssh_private_key_path != "" ? "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.bastion.public_ip}" : "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "connection_info" {
  description = "Connection information for the bastion instance"
  value = {
    instance_id = aws_instance.bastion.id
    public_ip   = aws_instance.bastion.public_ip
    private_ip  = aws_instance.bastion.private_ip
    ssh_user    = "ubuntu"
    key_name    = var.key_name
  }
}

output "available_tools" {
  description = "Testing and troubleshooting tools installed on the instance"
  value = {
    redis_cli         = "Redis command-line client"
    memtier_benchmark = "Redis load generation and benchmarking tool"
    kubectl           = var.install_kubectl ? "Kubernetes CLI" : "Not installed"
    aws_cli           = var.install_aws_cli ? "AWS CLI v2" : "Not installed"
    docker            = var.install_docker ? "Docker container runtime" : "Not installed"
  }
}

output "test_scripts_info" {
  description = "Information about test scripts available on the instance"
  value = {
    connection_test = "./test-redis-connection.sh <endpoint> <password>"
    benchmark       = "./run-memtier-benchmark.sh <endpoint> <password> [duration]"
    logs            = "/var/log/user-data.log"
    redis_endpoints = "Pre-configured Redis endpoints are available in /home/ubuntu/redis-endpoints.json"
  }
}

output "usage_examples" {
  description = "Example commands for using the bastion instance"
  value = {
    ssh             = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.bastion.public_ip}"
    test_redis      = "./test-redis-connection.sh redis.example.com:12000 mypassword"
    benchmark_redis = "./run-memtier-benchmark.sh redis.example.com:12000 mypassword 60"
    view_logs       = "tail -f /var/log/user-data.log"
    kubectl         = var.install_kubectl && var.eks_cluster_name != "" ? "kubectl get pods -n redis-enterprise" : "kubectl not configured"
  }
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the bastion instance (if EKS is configured)"
  value       = var.eks_cluster_name != "" ? aws_iam_role.bastion[0].arn : null
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name attached to the bastion instance (if EKS is configured)"
  value       = var.eks_cluster_name != "" ? aws_iam_instance_profile.bastion[0].name : null
}

output "kubectl_configured" {
  description = "Whether kubectl is automatically configured for EKS access"
  value       = var.install_kubectl && var.eks_cluster_name != ""
}
