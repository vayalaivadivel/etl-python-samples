region          = "us-east-1" 
rds_username    = "admin"
rds_password    = "Admin12345!"
vpc_cidr        = "10.0.0.0/16"

public_subnet1_cidr  = "10.0.1.0/24"   # AZ 1
public_subnet2_cidr  = "10.0.2.0/24"   # AZ 2

private_subnet1_cidr = "10.0.3.0/24"   # AZ 1
private_subnet2_cidr = "10.0.4.0/24"   # AZ 2
instance_type = "t3.large"
db_name="etl_dev"
my_ip_cidr = "115.98.161.44/32"