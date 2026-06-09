variable "aws_region" {
  description = "AWS Region"
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project Name"
}

variable "environment" {
  description = "Environment"
}

variable "mysql_schema_b64" {
  description = "Base64-encoded SQL schema content. Empty = skip schema apply."
  type        = string
  default     = ""
  sensitive   = true
}