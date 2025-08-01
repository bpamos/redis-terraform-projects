output "public_ip" {
  value = aws_instance.app.public_ip
}

output "private_ip" {
  value = aws_instance.app.private_ip
}

output "instance_id" {
  value = aws_instance.app.id
}

### Leaderboard App

output "leaderboard_url" {
  value       = "http://${aws_instance.app.public_ip}:5000"
  description = "URL to access the Flask leaderboard app"
}
