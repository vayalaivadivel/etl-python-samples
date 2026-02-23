
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnet_cidr" { default = "10.0.1.0/24" }
variable "private_subnet_cidr" { default = "10.0.2.0/24" }

variable "ec2_key_name" { 
    description = "EC2 key pair name" 
    type = string 
}
variable "rds_username" { type = string }
variable "rds_password" { type = string }