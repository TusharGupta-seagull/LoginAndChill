module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  enable_deletion_protection = false

  target_groups = {
    backend = {
      name_prefix       = "be-"
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/api/auth/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 20
        matcher             = "200"
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "backend"
      }
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
