terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_default_vpc" "default" {}

resource "aws_key_pair" "mac_key" {
  key_name   = "shivansh-macbook-key"
  public_key = file("~/.ssh/tf-ec2-key.pub")
}

resource "aws_security_group" "setup_sg" {
    name        = "todo-api-setup-sg"
    description = "Temporary SG for docker compose testing - SSH and HTTP open"
    vpc_id      = aws_default_vpc.default.id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
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
      Name = "todo-api-setup-sg"
    }
}

variable "packer_ami_id" {
  type        = string
  description = "AMI ID from packer build (cat packer/manifest.json)"
}

# Phase 1 test EC2 -- uses YOUR custom Packer AMI, not base Ubuntu
# Docker and images are already installed -- no waiting for apt-get
resource "aws_instance" "test_ec2" {
  ami           = var.packer_ami_id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.mac_key.key_name

  vpc_security_group_ids = [aws_security_group.setup_sg.id]

  # Lightweight user_data -- only clone + configure + run
  # No Docker install, no image pulls -- already in the AMI
  user_data = base64encode(<<-EOF
#!/bin/bash
set -euxo pipefail

# Docker already running from AMI -- just verify
systemctl start docker

# Clone the app into the directory created by the AMI
git clone https://github.com/ShivanshKumar760/todo-api.git /opt/todo-api
cd /opt/todo-api

# Write test env file (use local Postgres container for Phase 1)
cat > /etc/todo-api/env << 'ENVEOF'
DATABASE_URL=postgresql://todouser:testpass@postgres:5432/tododb
JWT_SECRET_KEY=dev-test-secret-not-for-production
ENVEOF
chmod 600 /etc/todo-api/env

# Local Postgres for Phase 1 testing
cat > /opt/todo-api/docker-compose.test.yml << 'COMPOSEEOF'
version: "3.9"
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: todouser
      POSTGRES_PASSWORD: testpass
      POSTGRES_DB: tododb
    networks: [url-net]
  flask-app:
    build: .
    environment:
      - DATABASE_URL=postgresql://todouser:testpass@postgres:5432/tododb
      - JWT_SECRET_KEY=dev-test-secret
    depends_on: [postgres]
    networks: [url-net]
  nginx:
    image: nginx:1.25-alpine
    ports: ["80:80"]
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on: [flask-app]
    networks: [url-net]
networks:
  url-net:
    driver: bridge
COMPOSEEOF

# python:3.11-slim and nginx:alpine already in AMI cache
# --build only rebuilds the app code layer (~30-45 seconds)
docker compose -f docker-compose.test.yml up --build -d

echo "Phase 1 test stack started (should be up in ~60s total from boot)"
EOF
  )
  tags = { Name = "todo-api-test-ec2" }
}

output "test_ec2_public_ip" {
  value       = aws_instance.test_ec2.public_ip
  description = "SSH: ssh -i ~/.ssh/tf-ec2-key ubuntu@<this-ip>"
}