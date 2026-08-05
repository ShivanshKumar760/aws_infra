# terraform/phase2/asg.tf
#
# Auto Scaling Group — manages the pool of EC2 instances.
# Also defines the scaling policy that decides WHEN to add/remove instances.

resource "aws_autoscaling_group" "todo_api" {
  name = "todo-api-asg"

  # Spread instances across all available subnets (one per AZ)
  # This means if one Availability Zone has an outage, instances in
  # the other AZs keep serving traffic
  vpc_zone_identifier = data.aws_subnets.all.ids

  # Connect ASG to the ALB target group
  # New instances automatically register with the ALB when they start
  target_group_arns = [aws_lb_target_group.todo_api.arn]

  desired_capacity = var.asg_desired   # Start with this many instances
  min_size         = var.asg_min_size  # Never go below this (always on)
  max_size         = var.asg_max_size  # Never create more than this

  # Use ELB health checks — if the ALB's /healthz check fails,
  # the ASG terminates the instance and launches a replacement
  health_check_type         = "ELB"
  health_check_grace_period = 120   # Wait 120s after launch before checking

  # After a scaling event, wait this long before another can trigger
  # Prevents rapid add/remove oscillation
  default_cooldown = 60

  # Reference the launch template we defined above
  launch_template {
    id      = aws_launch_template.todo_api.id
    version = "$Latest"  # Always use the newest version of the template
  }

  # These tags are copied to every EC2 instance the ASG launches
  tag {
    key                 = "Name"
    value               = "todo-api-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# ── Scaling Policy ─────────────────────────────────────────────────────────────
# Target Tracking: you set a target metric value, AWS manages the math.
# When the metric exceeds the target → add instances.
# When it drops back → remove instances.
#
# We track outbound network bytes (ASGAverageNetworkOut) like the blog does.
# A real production app would typically track CPU instead.

resource "aws_autoscaling_policy" "scale_on_network" {
  name                   = "todo-api-scale-on-network"
  autoscaling_group_name = aws_autoscaling_group.todo_api.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    # Keep average outbound bytes per instance near this target
    target_value = var.scale_target_network_out

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }
  }
}

# ── Optional: CPU-based scaling policy ────────────────────────────────────────
# Uncomment this if you want to scale based on CPU instead (more common)
#
# resource "aws_autoscaling_policy" "scale_on_cpu" {
#   name                   = "todo-api-scale-on-cpu"
#   autoscaling_group_name = aws_autoscaling_group.todo_api.name
#   policy_type            = "TargetTrackingScaling"
#
#   target_tracking_configuration {
#     target_value = 60.0   # Keep avg CPU at 60%
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#   }
# }