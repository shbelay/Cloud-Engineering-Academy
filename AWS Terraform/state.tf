terraform {
  backend "s3" {
    bucket = "my-terraform-state-shbelay"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-lock-file"
  }
}