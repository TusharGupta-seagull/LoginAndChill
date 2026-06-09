output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "ecs_execution_role_arn" {
  value = module.ecs_task_execution_role.iam_role_arn
}

output "ecs_task_role_arn" {
  value = module.ecs_task_role.iam_role_arn
}

output "backend_ecr_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "mysql_private_ip" {
  value     = aws_instance.mysql.private_ip
  sensitive = true
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  value = module.alb.dns_name
}