from pyspark.sql import SparkSession

def read_from_s3(spark, path):
    df = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .csv(path)
    return df