# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "pyspark-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
  Name = "public-subnet1"
}
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt1"
  }
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]  # second AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet2"
  }
}


resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}


data "aws_availability_zones" "available" {}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-public-subnet-group"
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "rds-public-subnet-group"
  }
}


# ---------------------------
# Security Group (Public MySQL Access)
# ---------------------------
resource "aws_security_group" "rds_sg" {
  name        = "rds-mysql-public-sg"
  description = "Allow MySQL inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["92.97.19.251/32"]  # 🔥 Replace with your IP (IMPORTANT)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# RDS MySQL Instance
# ---------------------------
resource "aws_db_instance" "mysql_rds" {
  identifier              = "lowcost-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"

  db_name                 = var.db_name
  username                = var.rds_username
  password                = var.rds_password   # use secrets manager in real prod

  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  backup_retention_period = 0  # 🔥 Disable backup to save cost
  multi_az                = false

  db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
  tags = {
  Name = "etl-mysql-rds"
}
}