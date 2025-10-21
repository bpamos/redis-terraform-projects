# =============================================================================
# REDIS CLOUD PROVIDER
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "rediscloud" {
  api_key    = var.rediscloud_api_key
  secret_key = var.rediscloud_secret_key
}

provider "aws" {
  region = "us-west-2"
}

# =============================================================================
# REDIS CLOUD RESOURCES
# Get payment method, create subscription, database, and VPC peering
# =============================================================================

# Get payment method for billing
data "rediscloud_payment_method" "card" {
  card_type         = "Mastercard"
  last_four_numbers = var.credit_card_last_four
}

# Create Redis Cloud subscription
resource "rediscloud_subscription" "subscription" {
  name           = "simple-redis-subscription"
  payment_method = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage = "ram"

  cloud_provider {
    provider = "AWS"
    cloud_account_id = 1
    region {
      region                     = "us-west-2"
      multiple_availability_zones = true
      networking_deployment_cidr  = "10.42.0.0/24"
    }
  }

  creation_plan {
    dataset_size_in_gb           = 1
    quantity                     = 1
    replication                  = true
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 1000
    modules                      = []
  }

  maintenance_windows {
    mode = "manual"
    window {
      start_hour        = 22
      duration_in_hours = 8
      days              = ["Sunday"]
    }
  }
}

# Create Redis database
resource "rediscloud_subscription_database" "database" {
  subscription_id              = rediscloud_subscription.subscription.id
  name                         = "simple-redis-db"
  dataset_size_in_gb           = 1
  data_persistence             = "aof-every-1-second"
  throughput_measurement_by    = "operations-per-second"
  throughput_measurement_value = 1000
  replication                  = true

  # Enable RedisJSON module
  modules {
    name = "RedisJSON"
  }
}

# =============================================================================
# VPC PEERING - REDIS CLOUD SIDE
# Initiate peering connection to AWS VPC
# =============================================================================

resource "rediscloud_subscription_peering" "peering" {
  subscription_id = rediscloud_subscription.subscription.id
  region          = "us-west-2"
  aws_account_id  = var.aws_account_id
  vpc_id          = aws_vpc.main.id
  vpc_cidr        = aws_vpc.main.cidr_block
}
