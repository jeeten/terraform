terraform {
  backend "s3" {
    bucket = "terraform-glob-state"
    region = "us-east-1"
    dynamodb_table = "terraform-glob-state"
    encrypt = true
    key    = "global/s3/terraform.tfstate"
  }
}