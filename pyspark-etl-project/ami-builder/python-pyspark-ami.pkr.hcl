packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" { default = "us-east-1" }

source "amazon-ebs" "python_pyspark_etl" {
  region               = var.aws_region
  ami_name             = "python-pyspark-etl-{{timestamp}}"
  instance_type        = "t3.medium"
  subnet_id            = "subnet-052166c21a4f8dcef" # your subnet
  iam_instance_profile = "Packer-SSM-Role"

  communicator = "session_manager"
  ssh_username = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  tags = {
    Name        = "python-pyspark-etl-ami"
    Environment = "dev"
  }
}

build {
  sources = ["source.amazon-ebs.python_pyspark_etl"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y python3 python3-pip openjdk-17-jdk scala git wget mysql-client",
      "sudo -H pip3 install --upgrade pip",
      "sudo -H pip3 install pyspark boto3 pandas sqlalchemy pymysql",
      "sudo mkdir -p /home/ubuntu/etl_project/{src,conf,logs}",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/etl_project"
    ]
  }
}