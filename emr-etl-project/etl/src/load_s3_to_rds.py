#!/usr/bin/env python3
import os
import yaml
from pyspark.sql import SparkSession, functions as F
from datetime import datetime
import traceback

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
    # CSV file location
    # -----------------------------
    csv_file = config.get("csv_file", "data/my-company-list.csv")

    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"CSV file not found at {csv_file}")
    
    log(f"CSV file found: {csv_file}")

    # -----------------------------
    # RDS configuration (dynamic)
    # -----------------------------
    rds = config.get("rds", {})
    rds_user = os.getenv("MYSQL_USER", rds.get("user"))
    rds_password = os.getenv("MYSQL_PASSWORD", rds.get("password"))
    rds_host = os.getenv("MYSQL_HOST", rds.get("host"))  # <-- use your endpoint here
    rds_port = os.getenv("MYSQL_PORT", str(rds.get("port", 3306)))
    rds_db = os.getenv("MYSQL_DATABASE", rds.get("database"))

    if not all([rds_user, rds_password, rds_host, rds_db]):
        raise ValueError("Missing RDS connection details!")

    jdbc_url = f"jdbc:mysql://{rds_host}:{rds_port}/{rds_db}?rewriteBatchedStatements=true"
    connection_properties = {
        "user": rds_user,
        "password": rds_password,
        "driver": "com.mysql.cj.jdbc.Driver"
    }

    log(f"Using RDS endpoint: {rds_host}:{rds_port}/{rds_db}")

    # -----------------------------
    # Initialize Spark
    # -----------------------------
    spark = SparkSession.builder \
        .appName("ETL CSV to RDS") \
        .getOrCreate()

    log("Spark session initialized")

    # -----------------------------
    # Read CSV
    # -----------------------------
    df = spark.read \
        .option("header", True) \
        .option("inferSchema", True) \
        .csv(csv_file)

    df.cache()
    log("CSV data loaded into Spark DataFrame")

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
    df.write \
        .mode("append") \
        .jdbc(url=jdbc_url, table="companies", properties=connection_properties)

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