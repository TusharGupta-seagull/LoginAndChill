# ALB Security Group
# Public access from Internet to ALB
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from Internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Project = var.project_name
  }
}


# ECS Security Group
# Only ALB can access backend containers
module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Backend access from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Project = var.project_name
  }
}


# MySQL EC2 Security Group
# Only ECS backend can access DB
module "mysql_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.project_name}-${var.environment}-mysql-sg"
  description = "Security group for MySQL EC2"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL access from ECS backend"
      source_security_group_id = module.ecs_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Project = var.project_name
  }
}