# =============================================================================
# REDIS CLOUD + VPC TERRAFORM PROJECT  
# Creates Redis Cloud subscription, AWS VPC, and VPC peering with EC2 testing
# =============================================================================
#
# This main file includes both Redis Cloud and AWS resources.
# For easier navigation and understanding, the resources are split into:
# 
# - main_redis_cloud.tf    : Redis Cloud subscription, database, and peering
# - main_aws_resources.tf  : AWS VPC, EC2, security groups, and observability
#
# You can examine each file separately to understand the specific resource types.
# =============================================================================