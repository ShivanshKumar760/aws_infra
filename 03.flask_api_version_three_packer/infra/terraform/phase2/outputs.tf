output "alb_dns_name" {
  value = aws_lb.todo_api.dns_name
  description = "ALB DNS - use this to access api"
}

output "alb_url" {
  value = "http://${aws_lb.todo_api.dns_name}"
  description = "Full URL to access our todo api"
}

output "postgres_private_ip" {
  value = aws_instance.postgres.private_ip
  description = "Private IP of the Postgres EC2-for debugging"
}

output "postgres_public_ip" {
  value = aws_instance.postgres.public_ip
  description = "Public IP of the Postgres EC2 for ssh access during maintenance"

}
output "asg_name" {
  value = aws_autoscaling_group.todo_api.name
  description = "ASG name"
}

output "database_url_template" {
  value = "postgresql://${var.pg_username}:***@${aws_instance.postgres.private_ip}:5432/${var.pg_database}"
  description = "DATABASE_URL template used by Flask instance"
  sensitive = false
}