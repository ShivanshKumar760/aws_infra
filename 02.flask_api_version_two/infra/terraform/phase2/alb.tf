resource "aws_s3_bucket" "alb_logs" {
  bucket = "todo-api-alb-logs-${data.aws_elb_service_account.main.id}"
  force_destroy = true
  tags = {Environment = var.environment}
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Sid = "AllowALBLogDelivery"
            Effect = "Allow"
            Principal = {AWS = data.aws_elb_service_account.main.arn}
            Action = "s3:PutObject"
            Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        }
    ]
  })
}

resource "aws_lb_target_group" "todo_api" {
  name = "todo-api-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/healthz"
    port = "traffic-port"
    protocol = "HTTP"
    interval = 30
    timeout = 20
    healthy_threshold = 2
    unhealthy_threshold = 3
    matcher = "200"
  }

  tags = {Environment = var.environment}
}


resource "aws_lb" "todo_api" {
  name = "todo-api-alb"
  load_balancer_type = "application"
  internal = false
  subnets = data.aws_subnets.all.ids
  security_groups = [aws_security_group.alb_sg.id]
  enable_cross_zone_load_balancing = true 
  enable_http2 = true
  idle_timeout = 60

  access_logs {
    bucket = aws_s3_bucket.alb_logs.bucket
    prefix = "todo-api-alb"
    enabled = true
  }

  depends_on = [ aws_s3_bucket_policy.alb_logs ]

  tags = {
    Name = "todo-api-alb"
    Environment = var.environment
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.todo_api.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.todo_api.arn
  }
}