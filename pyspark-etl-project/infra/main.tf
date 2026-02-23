
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "pyspark-vpc" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = { Name = "public-subnet" }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"
  tags = { Name = "private-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow SSH and outbound"
  ingress {
         from_port = 22
         to_port = 22
         protocol = "tcp"
         cidr_blocks = ["0.0.0.0/0"] 
    }
  egress  { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow MySQL from EC2"
  ingress { 
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] 
  }
  egress  { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}


# S3
#----------------------------------------
# Random suffix for bucket
#----------------------------------------
resource "random_id" "bucket_id" {
  byte_length = 4
}

#----------------------------------------
# S3 Bucket
#----------------------------------------
resource "aws_s3_bucket" "csv_bucket" {
  bucket = "pyspark-public-csv-${random_id.bucket_id.hex}"
  # Do NOT set acl, BucketOwnerEnforced prevents it
}

#----------------------------------------
# Enable Versioning
#----------------------------------------
resource "aws_s3_bucket_versioning" "csv_bucket_versioning" {
  bucket = aws_s3_bucket.csv_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#----------------------------------------
# Block Public Access
#----------------------------------------
resource "aws_s3_bucket_public_access_block" "csv_bucket_block" {
  bucket = aws_s3_bucket.csv_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#----------------------------------------
# Optional: IAM-based access policy
#----------------------------------------
# Remove public access; grant access only to specific IAM roles/users
# Example: allow your ETL role to read/write
resource "aws_s3_bucket_policy" "iam_policy" {
  bucket = aws_s3_bucket.csv_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowETLUserAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::091756093438:role/etl-role"  # replace with your role
        },
        Action   = ["s3:GetObject","s3:PutObject","s3:ListBucket"],
        Resource = [
          aws_s3_bucket.csv_bucket.arn,
          "${aws_s3_bucket.csv_bucket.arn}/*"
        ]
      }
    ]
  })
}




# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter { 
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] 
  }
}

resource "aws_instance" "pyspark_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  key_name               = var.ec2_key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  tags = { Name = "PySpark-EC2" }

  user_data = file("install_python.sh")
}


# RDS
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private.id]
  tags       = { Name = "rds-subnets" }
}

resource "aws_db_instance" "mysql_rds" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  identifier             = "pysparkdb-instance"
 # name                   = "pysparkdb"
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}