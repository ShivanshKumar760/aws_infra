# terraform/phase2/alb.tf
#
# Application Load Balancer + all its dependencies:
#   S3 bucket      → stores ALB access logs
#   Target Group   → the list of EC2 instances + health check config
#   ALB            → the public-facing load balancer
#   Listener       → the rule: "HTTP on port 80 → forward to target group"

# ── S3 Bucket for ALB access logs ─────────────────────────────────────────────
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "todo-api-alb-logs-${data.aws_elb_service_account.main.id}"
  force_destroy = true  # allow deleting even if bucket has files (for terraform destroy)

  tags = { Environment = var.environment }
}

# Bucket policy: allows the ELB service account to write log files here
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowALBLogDelivery"
      Effect = "Allow"
      Principal = {
        AWS = data.aws_elb_service_account.main.arn
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.alb_logs.arn}/*"
    }]
  })
}

# ── Target Group ───────────────────────────────────────────────────────────────
# The Target Group is the list of instances that receive traffic.
# It also defines HOW to health-check each instance.
resource "aws_lb_target_group" "todo_api" {
  name     = "todo-api-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # Health check: ALB hits /healthz every 30 seconds
  # If an instance fails 3 checks in a row → remove from rotation
  # If it passes 2 checks in a row after being unhealthy → add back
  health_check {
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"   # expect HTTP 200 response
  }

  tags = { Environment = var.environment }
}

# ── Application Load Balancer ──────────────────────────────────────────────────
resource "aws_lb" "todo_api" {
  name               = "todo-api-alb"
  load_balancer_type = "application"
  internal           = false   # internet-facing (has a public IP)

  # Deploy ALB across all subnets (one per AZ) for high availability
  subnets         = data.aws_subnets.all.ids
  security_groups = [aws_security_group.alb_sg.id]

  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60

  # Send access logs to S3
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "todo-api-alb"
    enabled = true
  }

  # Must wait for the bucket policy before the ALB can write logs
  depends_on = [aws_s3_bucket_policy.alb_logs]

  tags = {
    Name        = "todo-api-alb"
    Environment = var.environment
  }
}

# ── Listener ───────────────────────────────────────────────────────────────────
# Tells the ALB what to do with incoming traffic on port 80:
# "forward it to the todo_api target group"
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.todo_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.todo_api.arn
  }
}