#!/usr/bin/env python3
import os
import yaml
from pyspark.sql import SparkSession, functions as F
from sqlalchemy import create_engine, text
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

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
    with open("conf/config.yaml", "r") as f:
        config = yaml.safe_load(f)

    # -----------------------------
    # S3 bucket and path
    # -----------------------------
    s3_bucket = config["s3"]["bucket"]
    s3_key = config["s3"]["key"]
    s3_path = f"s3a://{s3_bucket}/{s3_key}"

    # -----------------------------
    # Verify S3 bucket access via IAM role
    # -----------------------------
    s3_client = boto3.client("s3")
    try:
        s3_client.head_bucket(Bucket=s3_bucket)
        log(f"✅ Access verified to S3 bucket '{s3_bucket}' using IAM role")
    except ClientError as e:
        log(f"❌ Unable to access S3 bucket '{s3_bucket}': {e}")
        raise

    log(f"S3 path: {s3_path}")

    # -----------------------------
    # RDS configuration from environment variables (safer in production)
    # -----------------------------
    rds = config["rds"]
    rds_user = os.getenv("MYSQL_USER", rds["user"])
    rds_password = os.getenv("MYSQL_PASSWORD", rds["password"])
    rds_host = os.getenv("MYSQL_HOST", rds["host"])
    rds_port = os.getenv("MYSQL_PORT", str(rds.get("port", 3306)))
    rds_db = os.getenv("MYSQL_DATABASE", rds["database"])

    # -----------------------------
    # Initialize Spark session
    # -----------------------------
    spark = SparkSession.builder \
        .appName("ETL S3 to RDS") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider",
                "com.amazonaws.auth.InstanceProfileCredentialsProvider") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .getOrCreate()
    log("Spark session initialized")

    # -----------------------------
    # Read CSV from S3
    # -----------------------------
    df = spark.read.option("header", True).csv(s3_path)
    log(f"Read {df.count()} rows from S3")

    # -----------------------------
    # Cast columns to correct types
    # -----------------------------
    for col_name, col_type in {
        "_num": "int",
        "_resultNumber": "int",
        "id": "int",
        "rank": "int",
        "workers": "int",
        "growth": "double",
        "yrs_on_list": "int"
    }.items():
        df = df.withColumn(col_name, F.col(col_name).cast(col_type))
    log("Columns casted successfully")

    # -----------------------------
    # JDBC properties for RDS
    # -----------------------------
    jdbc_url = f"jdbc:mysql://{rds_host}:{rds_port}/{rds_db}"
    connection_properties = {
        "user": rds_user,
        "password": rds_password,
        "driver": "com.mysql.cj.jdbc.Driver"
    }

    # -----------------------------
    # Create table if not exists
    # -----------------------------
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS companies (
        `_input` VARCHAR(255),
        `_num` INT,
        `_widgetName` VARCHAR(255),
        `_source` VARCHAR(255),
        `_resultNumber` INT,
        `_pageUrl` TEXT,
        `id` INT PRIMARY KEY,
        `rank` INT,
        `workers` INT,
        `company` VARCHAR(255),
        `url` TEXT,
        `state_l` VARCHAR(100),
        `state_s` VARCHAR(10),
        `city` VARCHAR(100),
        `metro` VARCHAR(100),
        `growth` DECIMAL(15,2),
        `revenue` VARCHAR(100),
        `industry` VARCHAR(255),
        `yrs_on_list` INT
    )
    """
    engine = create_engine(f"mysql+pymysql://{rds_user}:{rds_password}@{rds_host}:{rds_port}/{rds_db}")
    with engine.connect() as conn:
        conn.execute(text(create_table_sql))
    log("Table `companies` created or verified successfully")

    # -----------------------------
    # Write to MySQL RDS via spark-submit compatible JDBC
    # -----------------------------
    df.write.jdbc(
        url=jdbc_url,
        table="companies",
        mode="append",
        properties=connection_properties
    )
    log("Data written to RDS successfully")
    log("✅ ETL completed successfully!")

except Exception as e:
    log(f"❌ ETL failed: {e}")
    raise

finally:
    if 'spark' in locals():
        spark.stop()
        log("Spark session stopped")