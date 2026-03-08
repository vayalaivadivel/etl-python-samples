# ---------------------------
# Outputs
# ---------------------------

# EMR Serverless Application ID
output "emr_app_id" {
  description = "EMR Serverless Spark application ID"
  value       = aws_emrserverless_application.spark_app.id
}

# EMR Serverless Execution Role ARN
output "emr_exec_role_arn" {
  description = "EMR Serverless execution role ARN"
  value       = aws_iam_role.emr_s3_rds_role.arn
}

output "rds_endpoint"    { value = aws_db_instance.mysql_rds.endpoint }

output "emr_temp_bucket_name" {
  description = "Temporary S3 bucket used by EMR Serverless jobs"
  value       = aws_s3_bucket.emr_temp_bucket.id
}



