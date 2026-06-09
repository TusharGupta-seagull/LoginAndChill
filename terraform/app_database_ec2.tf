# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# MySQL EC2 Instance
resource "aws_instance" "mysql" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.mysql_sg.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.mysql.name

  associate_public_ip_address = false

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -ex
              
              yum update -y
              yum install -y mariadb-server awscli
              
              systemctl enable mariadb
              systemctl start mariadb

              if [ -n "$SCHEMA_CONTENT_B64" ]; then
                echo "$SCHEMA_CONTENT_B64" | base64 -d > /tmp/schema.sql
              elif [ -f /tmp/schema.sql ]; then
                # Fallback: if Jenkins didn't provide it, try local file (for manual testing)
                echo "Using local schema.sql"
              fi

              if [ -f /tmp/schema.sql ] && [ -s /tmp/schema.sql ]; then
                mysql -u root loginapp < /tmp/schema.sql
                echo "Schema applied successfully at $(date)" | tee -a /var/log/user-data.log
              else
                echo "Warning: No schema found, skipping migration" | tee -a /var/log/user-data.log
              fi
              
              mysql -u root <<SQL
                CREATE USER IF NOT EXISTS 'loginapp_user'@'%' IDENTIFIED BY '${random_password.db_password.result}';
                GRANT ALL PRIVILEGES ON loginapp.* TO 'loginapp_user'@'%';
                FLUSH PRIVILEGES;
              SQL
              
              aws s3 cp s3://${aws_s3_bucket.frontend.bucket}/schema.sql /tmp/schema.sql
              
              if [ -f /tmp/schema.sql ]; then
                mysql -u root loginapp < /tmp/schema.sql
                echo "Schema applied successfully at $(date)" | tee -a /var/log/user-data.log
              else
                echo "Failed to download schema.sql" | tee -a /var/log/user-data.log
              fi
              
              echo "MySQL setup completed at $(date)" | tee -a /var/log/user-data.log
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_iam_instance_profile.mysql]
}

# Password for MySQL User
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!@#$%^&*()-_=+"
}

# Secret for JWT
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}
