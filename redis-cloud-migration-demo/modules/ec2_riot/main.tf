resource "aws_instance" "riot" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    riotx_version          = var.riotx_version
    docker_compose_version = var.docker_compose_version
    enable_observability   = var.enable_observability
  })

  tags = {
    Name    = "${var.name_prefix}-riot-ec2"
    Owner   = var.owner
    Project = var.project
  }
}

resource "null_resource" "riotx_ready" {
  depends_on = [aws_instance.riot]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.riot.public_ip
    }

    inline = [
      "echo 'Waiting for riotx to be installed...'",
      "until command -v riotx; do echo 'riotx not found, waiting...'; sleep 5; done",
      "echo 'riotx is installed and ready.'"
    ]
  }
}
