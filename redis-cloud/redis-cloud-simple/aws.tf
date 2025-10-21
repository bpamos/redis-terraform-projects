# =============================================================================
# AWS RESOURCES
# VPC, subnets, internet gateway, route tables, and VPC peering acceptance
# =============================================================================

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "redis-cloud-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "redis-cloud-igw"
  }
}

# Create public subnets in two availability zones
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "redis-cloud-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "redis-cloud-public-2"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "redis-cloud-public-rt"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# VPC PEERING - AWS SIDE
# Accept the peering connection from Redis Cloud
# =============================================================================

# Accept VPC peering connection from Redis Cloud
resource "aws_vpc_peering_connection_accepter" "redis_cloud" {
  vpc_peering_connection_id = rediscloud_subscription_peering.peering.aws_peering_id
  auto_accept               = true

  tags = {
    Name = "redis-cloud-peering"
  }
}

# Add route to Redis Cloud network through peering connection
resource "aws_route" "redis_cloud" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "10.42.0.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.redis_cloud.id
}
