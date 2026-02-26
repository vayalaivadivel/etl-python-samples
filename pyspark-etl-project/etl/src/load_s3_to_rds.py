#!/usr/bin/env python3
import os
import yaml
from pyspark.sql import SparkSession, functions as F
from sqlalchemy import create_engine
from datetime import datetime
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError

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
    # AWS Credentials
    # -----------------------------
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    aws_region = os.getenv("AWS_DEFAULT_REGION", None)

    # If env variables not set, try config.yaml
    if not aws_access_key or not aws_secret_key:
        if "access_key" in config["s3"] and "secret_key" in config["s3"]:
            aws_access_key = config["s3"]["access_key"]
            aws_secret_key = config["s3"]["secret_key"]
            aws_region = config["s3"].get("region", "us-east-1")
            log("AWS credentials loaded from config.yaml")
        else:
            log("No AWS credentials found in environment or config.yaml, assuming IAM role...")
            aws_region = config["s3"].get("region", "us-east-1")

    # Set environment variables for Spark and boto3
    if aws_access_key and aws_secret_key:
        os.environ["AWS_ACCESS_KEY_ID"] = aws_access_key
        os.environ["AWS_SECRET_ACCESS_KEY"] = aws_secret_key
    if aws_region:
        os.environ["AWS_DEFAULT_REGION"] = aws_region

    # -----------------------------
    # Test S3 bucket access (specific bucket only)
    # -----------------------------
    s3_bucket = config["s3"]["bucket"]
    s3_key = config["s3"]["key"]
    s3_path = f"s3a://{s3_bucket}/{s3_key}"

    s3_client = boto3.client("s3")
    try:
        s3_client.head_bucket(Bucket=s3_bucket)
        log(f"AWS S3 bucket '{s3_bucket}' access verified")
    except (NoCredentialsError, PartialCredentialsError, ClientError) as e:
        log(f"⚠️ Unable to verify access to bucket '{s3_bucket}': {e}")
        raise

    log(f"S3 path: {s3_path}")

    # -----------------------------
    # RDS config
    # -----------------------------
    rds = config["rds"]
    rds_user = os.getenv("MYSQL_USER", rds["user"])
    rds_password = os.getenv("MYSQL_PASSWORD", rds["password"])
    rds_host = os.getenv("MYSQL_HOST", rds["host"])
    rds_port = os.getenv("MYSQL_PORT", rds["port"])
    rds_db = os.getenv("MYSQL_DATABASE", rds["database"])

    # -----------------------------
    # Initialize Spark session
    # -----------------------------
    spark = SparkSession.builder \
        .appName("ETL S3 to RDS") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .getOrCreate()
    log("Spark session initialized")

    # -----------------------------
    # Read CSV from S3
    # -----------------------------
    df = spark.read.option("header", True).csv(s3_path)
    log(f"Read {df.count()} rows from S3")

    # -----------------------------
    # Cast columns
    # -----------------------------
    df = df.withColumn("_num", F.col("_num").cast("int")) \
           .withColumn("_resultNumber", F.col("_resultNumber").cast("int")) \
           .withColumn("id", F.col("id").cast("int")) \
           .withColumn("rank", F.col("rank").cast("int")) \
           .withColumn("workers", F.col("workers").cast("int")) \
           .withColumn("growth", F.col("growth").cast("double")) \
           .withColumn("yrs_on_list", F.col("yrs_on_list").cast("int"))
    log("Columns casted successfully")

    # -----------------------------
    # JDBC properties
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
    engine = create_engine(
        f"mysql+pymysql://{rds_user}:{rds_password}@{rds_host}:{rds_port}/{rds_db}"
    )
    with engine.connect() as conn:
        conn.execute(create_table_sql)
    log("Table `companies` created or verified successfully")

    # -----------------------------
    # Write to MySQL RDS
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