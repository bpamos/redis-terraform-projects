terraform {
  required_version = ">= 1.3.0"

  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "~> 2.4.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
