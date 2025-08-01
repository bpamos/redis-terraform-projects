# =============================================================================
# SIMPLE VPC FOR REDIS MIGRATION
# =============================================================================

# Create the main VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# =============================================================================
# PUBLIC SUBNETS
# =============================================================================

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
      Tier = "Public"
    }
  )
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

# Route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# PRIVATE SUBNETS
# =============================================================================

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
      Tier = "Private"
    }
  )
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-private-rt"
    }
  )
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}