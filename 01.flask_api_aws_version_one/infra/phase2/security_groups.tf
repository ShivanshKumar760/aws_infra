# terraform/phase2/security_groups.tf
#
# Two security groups:
#   1. ALB security group  — accepts HTTP from the internet
#   2. EC2 security group  — only accepts traffic from the ALB
#
# This is the key security improvement over Phase 1:
# EC2 instances are no longer directly reachable from the internet.
# All traffic MUST go through the ALB first.

# Security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "todo-api-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "todo-api-alb-sg"
    Environment = var.environment
  }
}

# Security group for EC2 instances inside the ASG
# Notice: ingress ONLY allows traffic from the ALB's security group
# No SSH — we baked the AMI, so we never need to log in again
#  FIXED LINE (Standard ASCII Hyphen)
resource "aws_security_group" "ec2_sg" {
  name        = "todo-api-ec2-sg"
  description = "Allow HTTP from ALB only - no direct internet access"

  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    # This is a security group reference — only traffic FROM the ALB SG is allowed
    # NOT from any IP address, ONLY from resources inside alb_sg
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "todo-api-ec2-sg"
    Environment = var.environment
  }
}