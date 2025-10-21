terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "~> 2.4.1"
    }
  }
}