resource "null_resource" "memtier_script" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/run_memtier.sh"
    destination = "/home/ubuntu/run_memtier.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/run_memtier.sh"
    ]
  }
}
