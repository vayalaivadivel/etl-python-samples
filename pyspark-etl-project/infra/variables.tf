
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnet1_cidr" { default = "10.0.0.0/18" }
variable "public_subnet2_cidr" { default = "10.0.64.0/18" }
variable "private_subnet1_cidr" { default = "10.0.128.0/18" }
variable "private_subnet2_cidr" { default = "10.0.192.0/18" }


variable "ec2_key_name" { 
    description = "EC2 key pair name" 
    type = string 
}
variable "rds_username" { type = string }
variable "rds_password" { type = string }