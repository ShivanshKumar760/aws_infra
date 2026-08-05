# terraform/phase2/outputs.tf
#
# Outputs are printed at the end of `terraform apply`.
# Save these — you need the ALB URL to test your API.

output "alb_dns_name" {
  value       = aws_lb.todo_api.dns_name
  description = "The public DNS name of the ALB — use this to access your API"
}

output "alb_url" {
  value       = "http://${aws_lb.todo_api.dns_name}"
  description = "Full URL to your API"
}

output "asg_name" {
  value       = aws_autoscaling_group.todo_api.name
  description = "Auto Scaling Group name — use in AWS Console to watch scaling"
}

output "target_group_arn" {
  value       = aws_lb_target_group.todo_api.arn
  description = "Target Group ARN — check target health in AWS Console"
}