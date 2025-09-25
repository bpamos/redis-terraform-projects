resource "aws_instance" "test" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    redis_cloud_endpoint = var.redis_cloud_endpoint
    redis_cloud_password = var.redis_cloud_password
  })

  tags = {
    Name    = "${var.name_prefix}-${var.ec2_name_suffix}"
    Owner   = var.owner
    Project = var.project
  }
}

# Note: EC2 instance setup happens via user_data script
# Tools (Redis CLI, memtier_benchmark) install automatically
# Check /var/log/user-data.log on the instance for installation progress
