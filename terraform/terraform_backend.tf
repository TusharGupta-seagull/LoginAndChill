terraform {
  backend "s3" {
    bucket       = "loginapp-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
