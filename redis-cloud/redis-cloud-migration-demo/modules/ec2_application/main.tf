resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/scripts/user_data_redisarena_minimal.sh")

  tags = {
    Name    = "${var.name_prefix}-redisarena-ec2"
    Owner   = var.owner
    Project = var.project
  }
}

# Wait for EC2 instance to be fully ready
resource "null_resource" "wait_for_instance" {
  depends_on = [aws_instance.app]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "10m"
    }

    inline = [
      "echo '⏳ Waiting for instance to be fully ready...'",
      "until [ -f /tmp/ec2-setup-complete ]; do echo 'Waiting for user-data setup...'; sleep 10; done",
      "echo '✅ Instance is ready for application installation'",
      "sudo systemctl status nginx || echo 'Nginx status check'",
      "which python3 || echo 'Python3 check'",
      "which memtier_benchmark || echo 'Memtier check'"
    ]
  }
}

# Install packages (moved from user-data for reliability)
resource "null_resource" "install_packages" {
  depends_on = [null_resource.wait_for_instance]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "10m"
    }

    inline = [
      "echo '📦 Installing essential packages via Terraform provisioner...'",
      
      # Update package lists (should be fast with fixed mirror)
      "sudo apt-get update -y",
      
      # Install essential packages
      "sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential redis-tools curl nginx",
      
      "echo '✅ Essential packages installed successfully'"
    ]
  }
}

# Upload RedisArena application files
resource "null_resource" "upload_redisarena" {
  depends_on = [null_resource.install_packages]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = aws_instance.app.public_ip
    timeout     = "5m"
  }

  # Create upload directories first
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/redisarena",
      "mkdir -p /tmp/redisarena/templates",
      "mkdir -p /tmp/redisarena/static"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "5m"
    }
  }

  # Upload application files
  provisioner "file" {
    source      = "${path.module}/scripts/redis_arena.py"
    destination = "/tmp/redisarena/redis_arena.py"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/requirements.txt"
    destination = "/tmp/redisarena/requirements.txt"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_redisarena.sh"
    destination = "/tmp/redisarena/install_redisarena.sh"
  }

  # Upload Flask templates directory
  provisioner "file" {
    source      = "${path.module}/scripts/templates/"
    destination = "/tmp/redisarena/templates/"
  }

  # Upload Flask static assets directory
  provisioner "file" {
    source      = "${path.module}/scripts/static/"
    destination = "/tmp/redisarena/static/"
  }
}

# Install and configure RedisArena
resource "null_resource" "install_redisarena" {
  depends_on = [null_resource.upload_redisarena]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu" 
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "15m"
    }

    inline = [
      "echo '🚀 Installing RedisArena application...'",
      "chmod +x /tmp/redisarena/install_redisarena.sh",
      "bash /tmp/redisarena/install_redisarena.sh",
      "echo '✅ RedisArena installation completed'"
    ]
  }
}

# Configure Redis connection
resource "null_resource" "configure_redis" {
  depends_on = [null_resource.install_redisarena]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "5m"
    }

    inline = [
      "echo '⚙️ Configuring Redis connection...'",
      
      # Ensure .env file exists before modifying it
      "if [ ! -f /opt/redisarena/.env ]; then",
      "  echo '❌ .env file not found, installation may have failed'",
      "  exit 1",
      "fi",
      
      # Update Redis configuration in .env file
      "sudo sed -i 's/REDIS_HOST=.*/REDIS_HOST=${var.redis_host}/' /opt/redisarena/.env",
      "sudo sed -i 's/REDIS_PORT=.*/REDIS_PORT=${var.redis_port}/' /opt/redisarena/.env", 
      "sudo sed -i 's/REDIS_PASSWORD=.*/REDIS_PASSWORD=${var.redis_password}/' /opt/redisarena/.env",
      
      # Ensure proper ownership
      "sudo chown ubuntu:ubuntu /opt/redisarena/.env",
      "sudo chmod 600 /opt/redisarena/.env",
      
      # Verify configuration
      "echo '📋 Current Redis configuration:'",
      "grep -E '^REDIS_' /opt/redisarena/.env || echo 'No Redis config found'",
      
      "echo '✅ Redis configuration completed'"
    ]
  }
}

# Start RedisArena service
resource "null_resource" "start_redisarena" {
  depends_on = [null_resource.configure_redis]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.app.public_ip
      timeout     = "5m"
    }

    inline = [
      "echo '🚀 Starting RedisArena service...'",
      
      # Start the service directly with systemctl (manage.sh might have path issues)
      "sudo systemctl start redisarena",
      "sudo systemctl enable redisarena",
      
      # Wait for application to be ready
      "echo '⏳ Waiting for RedisArena to be ready...'",
      "for i in {1..30}; do",
      "  if curl -f -s http://localhost:5000/api/status > /dev/null 2>&1; then",
      "    echo '✅ RedisArena is responding on port 5000'",
      "    break",
      "  else", 
      "    echo 'Waiting for RedisArena... ($i/30)'",
      "    sleep 2",
      "  fi",
      "done",
      
      # Verify service is running
      "systemctl is-active redisarena || echo '⚠️ Service may not be active'",
      "ss -tulpn | grep :5000 || echo '⚠️ Port 5000 may not be listening'",
      
      # Show detailed status
      "echo '📊 Service Status:'",
      "sudo systemctl status redisarena --no-pager -l || true",
      
      "echo '🎮 RedisArena deployment completed!'"
    ]
  }
}
