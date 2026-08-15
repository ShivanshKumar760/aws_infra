# packer {
#     required_plugins {
#         amazon = {
#             source = "github.com/hashicorp/amazon"
#             version = ">= 1.3.0"
#         }
#     }
# }

# variable "region" {
#     type = string 
#     default = "ap-south-1"
# }

# variable "build_instance_type" {
#     type = string 
#     default "t3.small"
#     description="Temporary instance type for the build . t3.small faster than t3.micro for pulls."
# }

# variable "ami_name_prefix"{
#     type = string 
#     default = "todo-api"
# }

# data "amazon-ami" "ubuntu_22_04" {
#     region = var.region
#     filters = {
#         name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
#         root-device-type = "ebs"
#         virtualization-type = "hvm"
#     }
#     most_recent = true
#     owners = ["099720109477"] # Canonical offical
# }

# source "amazon-ebs" "todo_api_ami" {
#     region = var.region
#     source_ami = data.amazon-ami.ubuntu_22_04.id
#     instance_type = var.build_instance_type
#     ssh_username = "ubuntu"

#     #unique name per build using a timestamp

#     ami_name = "${var.ami_name_prefix}-${formatdate("YYYY-MM-DD-hhmm",timestamp())}"
#     ami_description = "Todo API : Ubuntu 22.04 + Docker + pre-pulled python:3.11-slime + nginx:alpine"

#     launch_block_device_mappings {
#         device_name = "/dev/sda1"
#         volume_size = 20 # GB - 8GB default too tight with cached images
#         volume_type = "gp3" #cheaper and faster than gp2
#         delete_on_termination = true 
#     }

#     tags = {
#         Name = "${var.ami_name_prefix}-base"
#         ManagedBy = "packer"
#         BaseAMI = data.amazon-ami.ubuntu_22_04.id
#         BuildDate = formatdate("YYYY-MM-DD",timestamp())
#         Project = "todo-api"
#     }

#     # Tag on the temporary EC2 so you can identify it in the console
#     run_tags = {
#         Name = "packer-todo-api-build"
#         Purpose = "temporary-packer-build"
#     }
# }

# build {
#     name = "todo-api-ami"
#     source = ["source.amazon-ebs.todo_api_ami"]

#     #Wait for ubuntu cloud-init to finish before starting our provisioners
#     provisioner "shell" {
#         inline = [
#             "echo 'Waiting for cloud-init ...'",
#             "cloud-init status --wait"
#             "echo 'cloud-init complete'"
#         ]
#     }

#     #upload install.sh from our computer to the temp ec2
#     provisioner "file"{
#         source = "install.sh"
#         destination = "/tmp/install.sh"
#     }

#     provisioner "shell" {
#         inline = [
#             "chmod +x /tmp/install.sh",
#             "sudo /tmp/install.sh"
#         ]
#     }

#     # Final verification 
#     provisioner "shell" {
#         inline = [
#             "docker --version",
#             "docker compose version",
#             "docker images",
#             "systemctl is-enabled todo-api &&  echo 'service enabled OK'"
#         ]
#     }

#     #Write manifest.json with the resulting AMI ID 
#     post-processor "manifest"{
#         output = "manifest.json"
#         strip_path = true
#     }
# }



packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "build_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Temporary instance type for the build. t3.small is faster than t3.micro for pulls."
}

variable "ami_name_prefix" {
  type    = string
  default = "todo-api"
}

data "amazon-ami" "ubuntu_22_04" {
  region = var.region
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"] # Canonical official
}

source "amazon-ebs" "todo_api_ami" {
  region        = var.region
  source_ami    = data.amazon-ami.ubuntu_22_04.id
  instance_type = var.build_instance_type
  ssh_username  = "ubuntu"

  # unique name per build using a timestamp
  ami_name        = "${var.ami_name_prefix}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  ami_description = "Todo API: Ubuntu 22.04 + Docker + pre-pulled python:3.11-slim + nginx:alpine"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20    # GB - 8GB default too tight with cached images
    volume_type           = "gp3" # cheaper and faster than gp2
    delete_on_termination = true
  }

  tags = {
    Name      = "${var.ami_name_prefix}-base"
    ManagedBy = "packer"
    BaseAMI   = data.amazon-ami.ubuntu_22_04.id
    BuildDate = formatdate("YYYY-MM-DD", timestamp())
    Project   = "todo-api"
  }

  # Tag on the temporary EC2 so you can identify it in the console
  run_tags = {
    Name    = "packer-todo-api-build"
    Purpose = "temporary-packer-build"
  }
}

build {
  name    = "todo-api-ami"
  sources = ["source.amazon-ebs.todo_api_ami"]

  # Wait for ubuntu cloud-init to finish before starting our provisioners
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "cloud-init status --wait",
      "echo 'cloud-init complete'",
    ]
  }

  # upload install.sh from our computer to the temp ec2
  provisioner "file" {
    source      = "install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh",
    ]
  }

  # Final verification
  provisioner "shell" {
    inline = [
        "sudo docker --version",
        "sudo docker compose version",
        "sudo docker images",
        "systemctl is-enabled todo-api && echo 'service enabled OK'",
        ]
    }

  # Write manifest.json with the resulting AMI ID
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}