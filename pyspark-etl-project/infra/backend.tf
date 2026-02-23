terraform {
  required_version = ">= 1.7.5"

  backend "s3" {
    bucket         = "vadivel-tf-state-buc"
    key            = "first-etl/dev/terraform.tfstate"  # path in S3
    region         = "us-east-1"
    encrypt        = true
  }
}