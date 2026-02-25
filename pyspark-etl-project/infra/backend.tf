terraform {
  required_version = ">= 1.7.5"

  backend "s3" {
    bucket         = "vadivel-tf-state-buc"
    key            = "ami-list/terraform.tfstate"  # path in S3
    region         = "us-east-1"
    encrypt        = true
  }
}