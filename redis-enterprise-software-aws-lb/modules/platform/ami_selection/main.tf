# =============================================================================
# PLATFORM-SPECIFIC AMI SELECTION
# =============================================================================
# Selects appropriate AMI based on platform (Ubuntu or RHEL)
# =============================================================================

# Data source for Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  count       = var.platform == "ubuntu" ? 1 : 0
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

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Data source for RHEL 9 AMI
data "aws_ami" "rhel" {
  count       = var.platform == "rhel" ? 1 : 0
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Local values for platform configuration
locals {
  platform_config = {
    ubuntu = {
      ami_id = var.platform == "ubuntu" ? data.aws_ami.ubuntu[0].id : null
      user   = "ubuntu"
    }
    rhel = {
      ami_id = var.platform == "rhel" ? data.aws_ami.rhel[0].id : null
      user   = "ec2-user"
    }
  }
  
  selected_config = local.platform_config[var.platform]
}