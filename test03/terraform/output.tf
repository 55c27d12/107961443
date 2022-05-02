output "aws_alb_dns" {
  value = aws_lb.tf-webapp-alb.dns_name
}

output "aws_db_dns" {
  value = aws_instance.tf-mongodb.private_dns
}

output "aws_alb_healthcheck_url" {
  value = "http://${aws_lb.tf-webapp-alb.dns_name}/healthcheck"
}
