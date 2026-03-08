output "public_ec2_public_ip" {
  description = "Public IP of the PySpark EC2 instance"
  value       = aws_instance.public_ec2.public_ip
}
output "rds_endpoint"    { value = aws_db_instance.mysql_rds.endpoint }
#output "s3_bucket"       { value = aws_s3_bucket.csv_bucket.bucket }



