# =============================================================================
# HAPROXY LOAD BALANCER FOR REDIS ENTERPRISE
# =============================================================================
# Self-managed HAProxy on EC2 for Redis Enterprise cluster management and database access
# =============================================================================

# Local values for platform-specific configuration
locals {
  platform_config = {
    ubuntu = {
      user       = "ubuntu"
      ami_filter = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      ami_owner  = "099720109477"
    }
    rhel = {
      user       = "ec2-user"
      ami_filter = "RHEL-9.*-x86_64-*"
      ami_owner  = "309956199498"
    }
  }

  selected_config = local.platform_config[var.platform]
}

# =============================================================================
# AMI SELECTION FOR HAPROXY INSTANCES
# =============================================================================

data "aws_ami" "haproxy" {
  most_recent = true
  owners      = [local.selected_config.ami_owner]

  filter {
    name   = "name"
    values = [local.selected_config.ami_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# SECURITY GROUP FOR HAPROXY
# =============================================================================

resource "aws_security_group" "haproxy" {
  name_prefix = "${var.name_prefix}-haproxy-"
  description = "Security group for HAProxy load balancers"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis Enterprise UI (8443)
  ingress {
    description = "Redis Enterprise UI"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Redis Enterprise API (9443)
  ingress {
    description = "Redis Enterprise REST API"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Database ports (10000-19999)
  ingress {
    description = "Redis database external access"
    from_port   = 10000
    to_port     = 19999
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # HAProxy stats (8404)
  ingress {
    description = "HAProxy statistics page"
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-haproxy-sg"
    Type = "HAProxy-SecurityGroup"
  })
}

# =============================================================================
# HAPROXY INSTANCES (HIGH AVAILABILITY)
# =============================================================================

resource "aws_instance" "haproxy" {
  count = 2 # Deploy 2 HAProxy instances for high availability

  ami                         = data.aws_ami.haproxy.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.haproxy.id]
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/scripts/haproxy_setup.sh", {
    redis_nodes = var.private_ips
  }))

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-haproxy-${count.index + 1}"
    Type = "HAProxy-LoadBalancer"
    Role = count.index == 0 ? "primary" : "secondary"
  })
}

# =============================================================================
# HAPROXY CONFIGURATION PROVISIONER
# =============================================================================

resource "null_resource" "haproxy_config" {
  count = length(aws_instance.haproxy)

  # Trigger configuration update when Redis nodes change
  triggers = {
    haproxy_instance_id = aws_instance.haproxy[count.index].id
    redis_nodes         = join(",", var.private_ips)
  }

  # Upload HAProxy configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/haproxy.cfg.tpl", {
      redis_nodes = var.private_ips
    })
    destination = "/tmp/haproxy.cfg"

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.haproxy[count.index].public_ip
      timeout     = "5m"
    }
  }

  # Apply configuration
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
      "sudo systemctl reload haproxy",
      "sudo systemctl enable haproxy",
      "echo 'HAProxy configuration updated successfully'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.haproxy[count.index].public_ip
      timeout     = "5m"
    }
  }

  depends_on = [aws_instance.haproxy]
}