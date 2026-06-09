
resource "aws_iam_policy" "secrets_read_policy" {
  name = "${var.project_name}-${var.environment}-secrets-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.app_secrets.arn
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}


# ECS Task Execution Role
module "ecs_task_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.39.0"

  create_role = true
  role_name   = "${var.project_name}-${var.environment}-ecs-execution-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.secrets_read_policy.arn
  ]

  number_of_custom_role_policy_arns = 2
  role_requires_mfa                 = false

}


# ECS Task Role
module "ecs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.39.0"

  create_role = true
  role_name   = "${var.project_name}-${var.environment}-ecs-task-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  custom_role_policy_arns = [
    aws_iam_policy.secrets_read_policy.arn
  ]

  number_of_custom_role_policy_arns = 1
  role_requires_mfa                 = false
}