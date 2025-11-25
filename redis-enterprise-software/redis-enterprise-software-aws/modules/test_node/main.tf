# =============================================================================
# REDIS ENTERPRISE TEST NODE
# =============================================================================
# EC2 instance for testing Redis Enterprise databases
# Includes Redis CLI and Memtier benchmark tools
# =============================================================================

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "test" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    redis_endpoint = var.redis_endpoint
    redis_password = var.redis_password
  })

  tags = merge(
    {
      Name    = "${var.name_prefix}-test-node"
      Owner   = var.owner
      Project = var.project
      Role    = "redis-test-client"
    },
    var.tags
  )
}

# Note: EC2 instance setup happens via user_data script
# Tools (Redis CLI, memtier_benchmark) install automatically
# Check /var/log/user-data.log on the instance for installation progress
