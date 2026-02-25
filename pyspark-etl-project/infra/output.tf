# output "ec2_public_ip" { value = aws_instance.pyspark_ec2.public_ip }
output "rds_endpoint"    { value = aws_db_instance.mysql_rds.endpoint }
#output "s3_bucket"       { value = aws_s3_bucket.csv_bucket.bucket }







