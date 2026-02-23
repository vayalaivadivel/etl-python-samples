import yaml
from pyspark.sql import SparkSession
import pyspark.sql.functions as F

# Load configuration
with open("../conf/config.yaml", "r") as f:
    config = yaml.safe_load(f)

rds = config["rds"]
s3_bucket = config["s3"]["bucket"]
s3_key = config["s3"]["key"]
s3_path = f"s3://{s3_bucket}/{s3_key}"

# Initialize Spark session
spark = SparkSession.builder.appName("S3_to_RDS").getOrCreate()

# Read CSV from S3
df = spark.read.option("header", True).option("inferSchema", True).csv(s3_path)

# Cast columns to match MySQL table
df = df.withColumn("_num", F.col("_num").cast("int")) \
       .withColumn("_resultNumber", F.col("_resultNumber").cast("int")) \
       .withColumn("id", F.col("id").cast("int")) \
       .withColumn("rank", F.col("rank").cast("int")) \
       .withColumn("workers", F.col("workers").cast("int")) \
       .withColumn("growth", F.col("growth").cast("double")) \
       .withColumn("yrs_on_list", F.col("yrs_on_list").cast("int"))

# JDBC connection properties
jdbc_url = f"jdbc:mysql://{rds['host']}:{rds['port']}/{rds['database']}"
properties = {
    "user": rds["user"],
    "password": rds["password"],
    "driver": "com.mysql.cj.jdbc.Driver"
}

# Write DataFrame to MySQL
df.write.jdbc(url=jdbc_url, table="companies", mode="append", properties=properties)

print("CSV successfully loaded into RDS 'companies' table!")