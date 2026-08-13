# terraform {
#   required_providers {
#     aws = {
#         source = "hashicorp/aws"
#         version = "~> 5.0"
#     }
#   }
# }

# provider "aws" {
#   region = "ap-south-1"
# }

# resource "aws_default_vpc" "default" {}

# resource "aws_key_pair" "mac_key" {
#   key_name = "shivansh-macbook-key"
#   public_key = file("~/.ssh/tf-ec2-key.pub")
# }

# resource "aws_security_group" "setup_sg" {
#     name = "todo-api-setup-sg"
#     description = "Temporary SG for docker compose testing - SSH and HTTP open"
#     vpc_id = aws_default_vpc.default.id


#     ingress {
#         description = "SSH"
#         from_port = 22
#         to_port = 22
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     ingress {
#         description = "HTTP"
#         from_port = 80
#         to_port = 80
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"]

#     }

#     tags = {
#       Name = "todo-api-setup-sg"
#     }

# }


# resource "aws_instance" "setup_ec2" {
#   ami = "ami-0f58b397bc5c1f2e8" #ubuntu 22.04 LTS  , ap-south-1
#   instance_type = "t3.micro"
#   key_name = aws_key_pair.mac_key.key_name

#   vpc_security_group_ids = [aws_security_group.setup_sg.id]

#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     set -euxo pipefail

#     #update system packages 
#     apt-get update -y
#     apt-get upgrade -y

#     #install docker 

#     curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 
#     sh /tmp/get-docker.sh 

#     #Enable and start Docker
#     systemctl enable docker 
#     systemctl start docker 
    
#     # Add ubuntu user to docker group so it can run docker without sudo
#     usermod -aG docker ubuntu 

#     #Install Docker Compose v2 (as a Docker CLI plugin)
#     mkdir -p /usr/local/lib/docker/cli-plugins
#     curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
#     -o /usr/local/lib/docker/cli-plugins/docker-compose
#     chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

#     #Verify Installation 
#     docker --version
#     docker compose version

#     echo "Docker setup complete .SSH in and run : git clone <your-repo> && cd <your-repo> && docker compose up -d"
#     EOF 
#   )

#   tags = {
#     Name = "todo-api-setup-ec2"
#   }
# }

# #Outputs 
# output "setup_ec2_public_ip" {
#   value = aws_instance.setup_ec2.public_ip
#   description = "SSH: ssh -i ~/.ssh/tf-ec2-key ubuntu@<this-ip>"
# }

# output "security_group_id" {
#     value = aws_security_group.setup_sg.id
#     description = "Setup security group ID"
# }


#New Script 
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

resource "aws_instance" "setup_ec2" {
  # Updated to modern official Ubuntu 24.04 LTS image for ap-south-1 (Mumbai)
  ami           = "ami-0f58b397bc5c1f2e8" 
  instance_type = "t3.micro"
  key_name      = aws_key_pair.mac_key.key_name

  vpc_security_group_ids = [aws_security_group.setup_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Update system package records
    apt-get update -y
    
    # Install native stable Docker & Docker Compose packages directly
    apt-get install -y docker.io docker-compose-v2

    # Enable and start the system container daemon background layer
    systemctl enable docker 
    systemctl start docker 
    
    # Add ubuntu user to docker group so it can run docker without sudo
    usermod -aG docker ubuntu 

    # Verify Installation outputs directly inside system logs
    docker --version
    docker compose version

    echo "Docker setup complete. SSH in and run: git clone <your-repo> && cd <your-repo> && docker compose up -d"
    EOF
  )

  tags = {
    Name = "todo-api-setup-ec2"
  }
}

#--------------------------------
# Outputs
#--------------------------------
output "setup_ec2_public_ip" {
  value       = aws_instance.setup_ec2.public_ip
  description = "SSH: ssh -i ~/.ssh/tf-ec2-key ubuntu@<this-ip>"
}

output "security_group_id" {
    value       = aws_security_group.setup_sg.id
    description = "Setup security group ID"
}
