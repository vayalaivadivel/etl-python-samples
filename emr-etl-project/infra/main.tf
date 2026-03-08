# =============================================
# VPC
# =============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "pyspark-vpc-${var.env}" }
}

data "aws_availability_zones" "available" {}

# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet1-${var.env}" }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet2-${var.env}" }
}

# Internet Gateway & Route Table
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt-${var.env}" }
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

# =============================================
# RDS MySQL
# =============================================
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-public-subnet-group-${var.env}"
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
  tags       = { Name = "rds-subnet-group-${var.env}" }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-mysql-sg-${var.env}"
  description = "Allow MySQL inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql_rds" {
  identifier              = "etl-mysql-${var.env}"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"

  db_name                 = var.db_name
  username                = var.rds_username
  password                = var.rds_password

  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  backup_retention_period = 0
  multi_az                = false
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.name

  tags = { Name = "etl-mysql-rds-${var.env}" }
}

# =============================================
# EMR Serverless Spark
# =============================================
resource "aws_emrserverless_application" "spark_app" {
  name          = "etl-spark-app-${var.env}"
  release_label = "emr-7.3.0"
  type          = "SPARK"

  network_configuration {
    subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
  }

  maximum_capacity {
    cpu    = "4 vCPU"
    memory = "16 GB"
    disk   = "50 GB"
  }

  tags = {
    Environment = var.env
  }
}

# =============================================
# IAM Role for EMR Serverless (limited S3 access)
# =============================================
resource "aws_iam_role" "emr_s3_rds_role" {
  name = "emr-serverless-s3-rds-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "emr-serverless.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "emr_policy" {
  name        = "EMRServerlessS3RDSPolicy-${var.env}"
  description = "Allow EMR Serverless to access only the fixed S3 bucket and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::vadivel-data-engineer",
          "arn:aws:s3:::vadivel-data-engineer/my-company-list/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_emr_policy" {
  role       = aws_iam_role.emr_s3_rds_role.name
  policy_arn = aws_iam_policy.emr_policy.arn
}