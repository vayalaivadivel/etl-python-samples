region          = "us-east-1"
ec2_key_name    = "common-key"
rds_username    = "admin"
rds_password    = "Admin12345!"
vpc_cidr        = "10.0.0.0/16"

public_subnet1_cidr  = "10.0.1.0/24"   # AZ 1
public_subnet2_cidr  = "10.0.2.0/24"   # AZ 2

private_subnet1_cidr = "10.0.3.0/24"   # AZ 1
private_subnet2_cidr = "10.0.4.0/24"   # AZ 2
instance_type = "t3.medium"
db_name="etl"
my_ip_cidr = "92.97.19.251/32"
custom_ami_id="ami-0210bc5bf67ac22e0"