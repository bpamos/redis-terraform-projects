output "rediscloud_subscription_id" {
  value = rediscloud_subscription.redis.id
}

output "database_id" {
  value = rediscloud_subscription_database.db.db_id
}

output "database_public_endpoint" {
  value = rediscloud_subscription_database.db.public_endpoint
}

output "database_private_endpoint" {
  value = rediscloud_subscription_database.db.private_endpoint
}

output "rediscloud_password" {
  value     = rediscloud_subscription_database.db.password
  sensitive = true
}