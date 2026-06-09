
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}-${var.environment}-app-secrets"
  recovery_window_in_days = 0

  description = "Runtime secrets for LoginApp backend"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets_value" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    DB_URL      = "jdbc:mysql://${aws_instance.mysql.private_ip}:3306/loginapp?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
    DB_USERNAME = "loginapp_user"
    DB_PASSWORD = random_password.db_password.result
    JWT_SECRET  = random_password.jwt_secret.result

    # Updated CORS for CloudFront + local dev
    CORS_ALLOWED_ORIGINS = join(",", [
      "https://${aws_cloudfront_distribution.frontend.domain_name}",
      "http://${module.alb.dns_name}",
      "http://localhost:8080",
      "http://localhost",
      "file://"
    ])
  })

  depends_on = [
    aws_cloudfront_distribution.frontend,
    module.alb,
    aws_instance.mysql,
    random_password.db_password,
    random_password.jwt_secret
  ]
}