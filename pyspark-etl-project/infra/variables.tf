
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
    type = string
}
variable "public_subnet1_cidr" { type = string}
variable "public_subnet2_cidr" { type = string}
variable "private_subnet1_cidr" {  type = string}
variable "private_subnet2_cidr" { type = string}
variable "db_name" { type = string}

variable "ec2_key_name" { 
    description = "EC2 key pair name" 
    type = string 
}
variable "rds_username" { type = string }
variable "rds_password" { type = string }

variable "instance_type" { type = string }
