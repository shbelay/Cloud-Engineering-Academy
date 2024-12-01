terraform {
  backend "s3" {
    bucket = "nextjs-portfolio-bucket-shbelay"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "my-db-website-table"
  }
}