# terraform/phase2/main.tf
#
# Provider configuration and data sources.
# "data sources" read existing AWS resources without creating them.
# We use the default VPC and its subnets so we don't have to create networking.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Read the default VPC that AWS creates for every account
# This saves us from having to create a VPC ourselves
data "aws_vpc" "default" {
  default = true
}

# Read all subnet IDs inside the default VPC
# These subnets span all Availability Zones in the region
# The ALB and ASG will use these to spread across AZs
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# The ELB service account is an AWS-internal account that needs permission
# to write ALB access logs to our S3 bucket
data "aws_elb_service_account" "main" {}