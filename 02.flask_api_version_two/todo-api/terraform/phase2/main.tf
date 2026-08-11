terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}


#All subnet across ap-south-1a , ap-south-1b , ap-south-1c
data "aws_subnets" "all" {
  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.default.id ]
  }
}

#Get One subnet for the postgres Instance (use ap-south-1a)

data "aws_subnet" "pg_subnet"{
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
    filter {
      name = "availabilityZone"
      values = ["ap-south-1a"]
    }
}

#ELB service account for s3 log bucket policy

data "aws_elb_service_account" "main" {

}


data "aws_key_pair" "mac_key" {
  key_name = var.key_name
}