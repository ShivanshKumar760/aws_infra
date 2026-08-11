resource "aws_security_group" "alb_sg" {
  name = "todo-api-alb-sg"
  description = "Allow http and https from internet to ALB"
  vpc_id = data.aws_vpc.default.id


  ingress {
    description = "HTTP from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTPS from internet"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  tags = {
    Name = "todo-api-alb-sg"
    Environment = var.environment
  }
}


resource "aws_security_group" "ec2_sg" {
  name = "todo-api-ec2-sg"
  description = "Allow http from alb and ssh for debugging"
  vpc_id = data.aws_vpc.default.id


  ingress {
    description = "HTTP from alb"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }


  ingress {
    description = "SSH for debugging"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  tags = {
    Name = "todo-api-ec2-sg"
    Environment = var.environment
  }
}


resource "aws_security_group" "pg_sg" {
  name = "todo-api-pg-sg"
  description = "Allow PostgreSQL only from ec2 app instance"
  vpc_id = data.aws_vpc.default.id


  ingress {
    description = "PostgreSQL from EC2 app instance"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }


  ingress {
    description = "SSH for debugging"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  tags = {
    Name = "todo-api-pg-sg"
    Environment = var.environment
  }
}