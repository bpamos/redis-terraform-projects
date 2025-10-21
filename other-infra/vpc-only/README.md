# VPC-Only Terraform Project

This project creates a standalone AWS VPC infrastructure that can be used as a foundation for other Redis migration projects.

## What This Creates

- **VPC**: Virtual Private Cloud with configurable CIDR
- **Public Subnets**: 2 public subnets across different AZs
- **Private Subnets**: 2 private subnets across different AZs
- **Internet Gateway**: For public subnet internet access
- **Route Tables**: Properly configured routing

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- An AWS account with VPC creation permissions

## Quick Start

1. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get outputs**:
   ```bash
   terraform output
   ```

## Configuration

### Required Variables

- `name_prefix`: Unique prefix for all resources
- `owner`: Your name or team identifier

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `public_subnet_cidrs`: Public subnet CIDRs
- `private_subnet_cidrs`: Private subnet CIDRs
- `azs`: Availability zones to use

## Outputs

The module provides these outputs for use in other projects:

- `vpc_id`: VPC identifier
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `internet_gateway_id`: Internet Gateway ID
- `route_table_id`: Route table ID

## Usage with Other Projects

This VPC can be referenced by other Terraform projects using remote state:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../vpc-only/terraform.tfstate"
  }
}

# Use VPC outputs
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```