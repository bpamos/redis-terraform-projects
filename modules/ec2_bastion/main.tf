# =============================================================================
# EC2 BASTION MODULE
# =============================================================================
# Reusable EC2 bastion/testing node for Redis deployments
# Supports: Redis testing, troubleshooting, admin tasks, monitoring
# =============================================================================

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# SECURITY GROUP (if not provided)
# =============================================================================

resource "aws_security_group" "bastion" {
  count = var.security_group_id == "" ? 1 : 0

  name_prefix = "${var.name_prefix}-bastion-"
  description = "Security group for Redis bastion/testing node"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name    = "${var.name_prefix}-bastion-sg"
      Owner   = var.owner
      Project = var.project
      Role    = "bastion-security-group"
    },
    var.tags
  )
}

# =============================================================================
# IAM ROLE FOR EKS ACCESS (Optional - only when EKS cluster is configured)
# =============================================================================

resource "aws_iam_role" "bastion" {
  count = var.eks_cluster_name != "" ? 1 : 0

  name_prefix = "${var.name_prefix}-bastion-"
  description = "IAM role for bastion instance to access EKS cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(
    {
      Name    = "${var.name_prefix}-bastion-role"
      Owner   = var.owner
      Project = var.project
      Role    = "bastion-iam-role"
    },
    var.tags
  )
}

# =============================================================================
# IAM POLICY FOR EKS READ ACCESS
# =============================================================================

resource "aws_iam_role_policy" "bastion_eks_access" {
  count = var.eks_cluster_name != "" ? 1 : 0

  name_prefix = "eks-access-"
  role        = aws_iam_role.bastion[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# IAM INSTANCE PROFILE
# =============================================================================

resource "aws_iam_instance_profile" "bastion" {
  count = var.eks_cluster_name != "" ? 1 : 0

  name_prefix = "${var.name_prefix}-bastion-"
  role        = aws_iam_role.bastion[0].name

  tags = merge(
    {
      Name    = "${var.name_prefix}-bastion-profile"
      Owner   = var.owner
      Project = var.project
      Role    = "bastion-instance-profile"
    },
    var.tags
  )
}

# =============================================================================
# EC2 BASTION INSTANCE
# =============================================================================

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_id != "" ? [var.security_group_id] : [aws_security_group.bastion[0].id]
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip
  iam_instance_profile        = var.eks_cluster_name != "" ? aws_iam_instance_profile.bastion[0].name : null

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    redis_endpoints  = jsonencode(var.redis_endpoints)
    install_kubectl  = tostring(var.install_kubectl)
    install_aws_cli  = tostring(var.install_aws_cli)
    install_docker   = tostring(var.install_docker)
    eks_cluster_name = var.eks_cluster_name
    aws_region       = var.aws_region
  })

  tags = merge(
    {
      Name    = "${var.name_prefix}-bastion"
      Owner   = var.owner
      Project = var.project
      Role    = "bastion-host"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Note: EC2 instance setup happens via user_data script
# Tools install automatically: redis-cli, memtier_benchmark, kubectl, AWS CLI
# Check /var/log/user-data.log on the instance for installation progress
