# terraform/phase2/variables.tf
#
# All configurable values in one place.
# Override defaults by creating a terraform.tfvars file:
#   ami_id = "ami-0abc123def456789"

variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region to deploy into"
}

variable "ami_id" {
  type        = string
  description = "The custom AMI ID you created in Phase 1 (from Image → Create Image)"
  # Example: "ami-08f3c04e8b4b32ce5"
  # You MUST set this — no default because it's unique to your account
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the ASG"
}

variable "asg_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of EC2 instances the ASG keeps running"
}

variable "asg_max_size" {
  type        = number
  default     = 3
  description = "Maximum number of EC2 instances the ASG can create"
}

variable "asg_desired" {
  type        = number
  default     = 2
  description = "Starting number of EC2 instances"
}

variable "scale_target_network_out" {
  type        = number
  default     = 4000
  description = "Scale out when average outbound bytes per instance exceeds this"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment tag applied to all resources"
}