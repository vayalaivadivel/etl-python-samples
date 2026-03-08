#!/usr/bin/env python3
import os
import yaml
from pyspark.sql import SparkSession, functions as F
from datetime import datetime
import argparse
import traceback
import boto3
from botocore.exceptions import ClientError

# -----------------------------
# Argument parsing for config
# -----------------------------
parser = argparse.ArgumentParser(description="ETL PySpark job")
parser.add_argument("--config", required=True, help="Path to config YAML")
args = parser.parse_args()

config_path = args.config

# -----------------------------
# Prepare logs
# -----------------------------
os.makedirs("logs", exist_ok=True)
timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
log_file = f"logs/etl_{timestamp}.log"

def log(msg):
    with open(log_file, "a") as f:
        f.write(f"{datetime.now()} - {msg}\n")
    print(msg)

try:
    log("Starting ETL job...")

    # -----------------------------
    # Load configuration
    # -----------------------------
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)

    # -----------------------------
    # S3 configuration (data only)
    # -----------------------------
    s3_bucket = config["s3"]["bucket"]
    s3_key = config["s3"]["key"]
    s3_path = f"s3a://{s3_bucket}/{s3_key}"

    # Verify S3 bucket access
    s3_client = boto3.client("s3")
    try:
        s3_client.head_bucket(Bucket=s3_bucket)
        log(f"Access verified for bucket {s3_bucket}")
    except ClientError as e:
        log(f"S3 access error: {e}")
        raise

    # -----------------------------
    # RDS configuration
    # -----------------------------
    rds = config["rds"]
    rds_user = os.getenv("MYSQL_USER", rds["user"])
    rds_password = os.getenv("MYSQL_PASSWORD", rds["password"])
    rds_host = os.getenv("MYSQL_HOST", rds["host"])
    rds_port = os.getenv("MYSQL_PORT", str(rds.get("port", 3306)))
    rds_db = os.getenv("MYSQL_DATABASE", rds["database"])

    jdbc_url = f"jdbc:mysql://{rds_host}:{rds_port}/{rds_db}?rewriteBatchedStatements=true"
    connection_properties = {
        "user": rds_user,
        "password": rds_password,
        "driver": "com.mysql.cj.jdbc.Driver"
    }

    # -----------------------------
    # Initialize Spark
    # -----------------------------
    spark = SparkSession.builder \
        .appName("ETL S3 to RDS") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider",
                "com.amazonaws.auth.InstanceProfileCredentialsProvider") \
        .getOrCreate()

    log("Spark session initialized")

    # -----------------------------
    # Read CSV from S3
    # -----------------------------
    df = spark.read.option("header", True).option("inferSchema", True).csv(s3_path)
    df.cache()
    log("Data loaded from S3")

    # -----------------------------
    # Cast columns
    # -----------------------------
    cast_columns = {
        "_num": "int",
        "_resultNumber": "int",
        "id": "int",
        "rank": "int",
        "workers": "int",
        "growth": "double",
        "yrs_on_list": "int"
    }

    for col_name, col_type in cast_columns.items():
        if col_name in df.columns:
            df = df.withColumn(col_name, F.col(col_name).cast(col_type))
    log("Column casting completed")

    # -----------------------------
    # Write to MySQL RDS
    # -----------------------------
    df.write.mode("append").jdbc(url=jdbc_url, table="companies", properties=connection_properties)
    log("Data successfully written to RDS")
    log("ETL job completed successfully")

except Exception as e:
    log("ETL failed")
    log(str(e))
    log(traceback.format_exc())
    raise

finally:
    if 'spark' in locals():
        spark.stop()
        log("Spark session stopped")