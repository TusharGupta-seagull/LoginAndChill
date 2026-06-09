# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# MySQL EC2 Instance
resource "aws_instance" "mysql" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  key_name = "loginapp-dev-key"
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
              
              export SCHEMA_CONTENT_B64="${var.mysql_schema_b64}"
              
              dnf update -y
              dnf install -y mariadb118-server awscli
              
              systemctl enable mariadb
              systemctl start mariadb
              
              #retry up to 30 times
              for i in {1..30}; do
                mariadb -u root -e "SELECT 1" > /dev/null 2>&1 && break
                echo "Waiting for MariaDB... attempt $i/30"
                sleep 2
              done
              
              mariadb -u root <<SQL
                CREATE DATABASE IF NOT EXISTS loginapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
              SQL
              
              mariadb -u root <<SQL
                CREATE USER IF NOT EXISTS 'loginapp_user'@'%' IDENTIFIED BY '${random_password.db_password.result}';
                GRANT ALL PRIVILEGES ON loginapp.* TO 'loginapp_user'@'%';
                FLUSH PRIVILEGES;
              SQL
              
              if [ -n "$SCHEMA_CONTENT_B64" ] && [ "$SCHEMA_CONTENT_B64" != "null" ]; then
                echo "Apply schema from Jenkins secret at $(date)" | tee -a /var/log/user-data.log
                echo "$SCHEMA_CONTENT_B64" | base64 -d > /tmp/schema.sql
                
                if [ -s /tmp/schema.sql ]; then
                  mariadb -u root loginapp < /tmp/schema.sql
                  echo "Schema applied from Jenkins at $(date)" | tee -a /var/log/user-data.log
                else
                  echo "Schema from Jenkins was empty, skipping" | tee -a /var/log/user-data.log
                fi
                
                # Delete schema file
                shred -u /tmp/schema.sql 2>/dev/null || rm -f /tmp/schema.sql
              else
                echo "No schema provided (SCHEMA_CONTENT_B64 empty), skipping schema apply" | tee -a /var/log/user-data.log
              fi
              
              echo "MariaDB setup completed at $(date)" | tee -a /var/log/user-data.log
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [module.vpc.natgw_ids, aws_iam_instance_profile.mysql]
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