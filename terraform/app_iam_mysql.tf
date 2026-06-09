resource "aws_iam_role" "mysql" {
  name = "${var.project_name}-${var.environment}-mysql-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "mysql_s3" {
  name = "${var.project_name}-${var.environment}-mysql-s3-read"
  role = aws_iam_role.mysql.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject"
      ]
      Resource = "${aws_s3_bucket.frontend.arn}/schema.sql"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "mysql_ssm" {
  role       = aws_iam_role.mysql.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "mysql" {
  name = "${var.project_name}-${var.environment}-mysql-profile"
  role = aws_iam_role.mysql.name
}
