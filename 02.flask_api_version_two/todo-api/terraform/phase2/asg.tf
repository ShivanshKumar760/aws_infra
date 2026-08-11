resource "aws_autoscaling_group" "todo_api" {
  name = "todo-api-asg"
  vpc_zone_identifier = data.aws_subnets.all.ids
  target_group_arns = [ aws_lb_target_group.todo_api.arn ]
  desired_capacity = var.asg_desired
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  health_check_type = "ELB"
  health_check_grace_period = 300
  default_cooldown = 60

  launch_template {
    id = aws_launch_template.todo_api.id
    version = "$Latest"
  }

  tag {
    key = "Name"
    value = "todo-api-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key = "Environment"
    value = var.environment
    propagate_at_launch = true
  }
}

#----- Scaling Policy --------------------------------------------------------------
resource "aws_autoscaling_policy" "name" {
  name = "todo-api-scale-on-network"
  autoscaling_group_name = aws_autoscaling_group.todo_api.name
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = var.scale_target_network_out
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }
  }
}