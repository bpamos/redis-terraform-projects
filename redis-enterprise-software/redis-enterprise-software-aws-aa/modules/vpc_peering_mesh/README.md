# VPC Peering Mesh Module

Creates a full mesh of VPC peering connections between multiple AWS regions for Redis Enterprise Active-Active deployments.

## Purpose

Enables Redis Enterprise clusters in different regions to communicate for Active-Active (CRDB) database replication and coordination.

## Features

- **Full Mesh Topology**: Creates peering connections between all region pairs
- **Automatic Route Updates**: Configures route tables for cross-region traffic
- **Multi-Region Support**: Works with 2+ regions
- **Auto-Accept**: Automatically accepts peering connections

## Peering Topology

```
For 2 regions: 1 peering connection
    Region 1 <-> Region 2

For 3 regions: 3 peering connections
    Region 1 <-> Region 2
    Region 1 <-> Region 3
    Region 2 <-> Region 3

For N regions: N*(N-1)/2 connections
```

## Usage

```hcl
module "vpc_peering_mesh" {
  source = "./modules/vpc_peering_mesh"

  name_prefix = "redis-aa"

  region_configs = {
    "us-west-2" = {
      vpc_id                 = module.cluster_us_west_2.vpc_id
      vpc_cidr               = "10.0.0.0/16"
      private_route_table_id = module.cluster_us_west_2.private_route_table_id
    }
    "us-east-1" = {
      vpc_id                 = module.cluster_us_east_1.vpc_id
      vpc_cidr               = "10.1.0.0/16"
      private_route_table_id = module.cluster_us_east_1.private_route_table_id
    }
  }

  owner   = "YourName"
  project = "redis-active-active"
}
```

## Requirements

- VPC CIDRs must not overlap across regions
- Each VPC must have a private route table
- Appropriate IAM permissions for VPC peering

## Resources Created

- VPC peering connections between all region pairs
- VPC peering connection accepters
- Routes in private route tables for cross-region traffic

## Outputs

- `peering_connection_ids`: Map of peering connection IDs
- `peering_connection_status`: Status of each peering connection
- `region_pairs`: List of region pairs that have been peered
