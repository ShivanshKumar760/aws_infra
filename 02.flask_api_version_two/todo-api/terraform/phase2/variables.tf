variable "region" {
  type = string
  default = "ap-south-1"
  description = "AWS region - Mumbai"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
  description = "EC2 instance type for the ASG (flask app instance)"
}

variable "ami_id" {
  type = string
  default = "ami-0e159ea61d9821166"
  description = "Ubuntu 24.04 LTS AMI in ap-south-1"
}

variable "key_name" {
  type = string
  default = "shivansh-macbook-key"
  description = "EC2 Key pain name for ssh access"
}

variable "app_repo_url" {
  type = string 
  description = "Git repo url to clone on each ec2 instance"
  #Example : "https://github.com/Username/repo.git"
}

variable "app_repo_branch" {
  type = string 
  default = "master"
  description = "Branch to checkout"
}

#PostgreSQL Config
variable "pg_username" {
  type = string 
  default = "todouser"
  description = "PostgreSQL username"

}

variable "pg_password" {
  type = string
  sensitive = true
  description = "PostgreSQL password (mark sensitive so it's hidden in logs)"
}

variable "pg_database" {
  type = string 
  default = "tododb"
  description = "PostgreSQL database name"
}

#JWT Config

variable "jwt_secret_key" {
  type = string
  sensitive = true 
  description = "JWT signing secret"
}

#ASG Config

variable "asg_min_size" {
  type = number
  default = 1
}

variable "asg_max_size" {
  type = number 
  default = 3
}

variable "asg_desired" {
  type = number
  default = 2
}

variable "scale_target_network_output" {
  type = number
  default = 4000
}

variable "environment" {
  type = string
  default = "production"
}