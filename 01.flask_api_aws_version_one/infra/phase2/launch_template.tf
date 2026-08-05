# terraform/phase2/launch_template.tf
#
# The Launch Template is the blueprint for every EC2 instance the ASG creates.
# It references your custom AMI — so every new instance already has your
# Flask app, Gunicorn, and Nginx installed and running.

resource "aws_launch_template" "todo_api" {
  name_prefix   = "todo-api-"
  image_id      = var.ami_id          # Your custom AMI from Phase 1
  instance_type = var.instance_type   # t2.micro by default

  # Attach the EC2 security group
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # User data runs once when each new instance boots.
  # Since your app is already in the AMI, this just ensures
  # the services are started (in case they didn't start on boot).
  user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl start gunicorn
    systemctl start nginx
  EOF
  )

  # Tags applied to each instance launched by the ASG
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "todo-api-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true  # create new version before destroying old
  }
}