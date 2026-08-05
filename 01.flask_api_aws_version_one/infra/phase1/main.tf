#--------------------------------
# Terraform Block
#--------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Aligned to your Phase 1 specification
    }
  }
}

#--------------------------------
# Provider Configuration
#--------------------------------
provider "aws" {
  region = "ap-south-1" # Shifted to us-east-1 based on your Phase 1 prompt
}

#--------------------------------
# Data / Network Resources
#--------------------------------
# Automatically discovers your account's Default VPC in ap-south-1

resource "aws_default_vpc" "default" {}

#--------------------------------
# Resource Configuration
#--------------------------------

# Uploads your MacBook's public SSH key to the ap-south-1 region
resource "aws_key_pair" "mac_key" {
  key_name   = "shivansh-macbook-key"
  public_key = file("~/.ssh/tf-ec2-key.pub")
}

# Phase 1: Security Group for the setup EC2 instance
#  NEW FIXED CODE (Standard ASCII characters only)
resource "aws_security_group" "setup_sg" {
  name        = "todo-api-setup-sg"
  description = "Temporary SG for AMI creation - SSH and HTTP open"
  vpc_id      = aws_default_vpc.default.id


  # Allow SSH from anywhere so you can log in
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP so you can test the app before creating the AMI
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound (so the instance can download packages, pull from GitHub)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "todo-api-setup-sg" 
  }
}

# Launches your Setup EC2 instance attached to the Phase 1 Security Group
resource "aws_instance" "demo_ec2" {
  # ⚠️ Note: Ensure this AMI exists in us-east-1. 
  # (ami-00d2dbb426772b03a was for Mumbai. An excellent default Ubuntu 24.04 LTS AMI for us-east-1 is ami-0e2c8caa4b6378d8c)
  ami           = "ami-00d2dbb426772b03a"
  instance_type = "t3.micro"
  
  # Links the uploaded key pair from above
  key_name      = aws_key_pair.mac_key.key_name 

  # Binds the instance to your combined Phase 1 setup security group
  vpc_security_group_ids = [aws_security_group.setup_sg.id]

  tags = {
    Name = "tf-demo-setup"
  }
}

#--------------------------------
# Outputs
#--------------------------------
output "security_group_id" {
  value       = aws_security_group.setup_sg.id
  description = "Use this SG ID when launching the setup EC2 instance"
}

output "ec2_public_ip" {
  value       = aws_instance.demo_ec2.public_ip
  description = "The public IP address of your setup EC2 instance"
}
