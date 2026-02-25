import os
import yaml
from pyspark.sql import SparkSession, functions as F
from sqlalchemy import create_engine

# -----------------------------
# Load configuration
# -----------------------------
with open("conf/config.yaml", "r") as f:
    config = yaml.safe_load(f)

# S3 Config
s3_bucket = config["s3"]["bucket"]
s3_key = config["s3"]["key"]
s3_path = f"s3a://{s3_bucket}/{s3_key}"

# RDS Config
rds = config["rds"]

# -----------------------------
# Initialize Spark session
# -----------------------------
spark = SparkSession.builder \
    .appName("ETL S3 to RDS") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# -----------------------------
# Read CSV from S3
# -----------------------------
df = spark.read.option("header", True).csv(s3_path)

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

# -----------------------------
# JDBC properties
# -----------------------------
jdbc_url = f"jdbc:mysql://{rds['host']}:{rds['port']}/{rds['database']}"

connection_properties = {
    "user": rds["user"],
    "password": rds["password"],
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
    f"mysql+pymysql://{rds['user']}:{rds['password']}@{rds['host']}:{rds['port']}/{rds['database']}"
)

with engine.connect() as conn:
    conn.execute(create_table_sql)

# -----------------------------
# Write to MySQL RDS
# -----------------------------
df.write.jdbc(
    url=jdbc_url,
    table="companies",
    mode="append",
    properties=connection_properties
)

print("✅ ETL completed successfully!")

spark.stop()