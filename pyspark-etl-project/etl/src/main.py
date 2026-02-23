from pyspark.sql import SparkSession
from s3_reader import read_from_s3
from transformer import transform_data
from rds_writer import write_to_rds
import config

def main():
    spark = SparkSession.builder \
        .appName("S3 to RDS ETL") \
        .getOrCreate()

    df = read_from_s3(spark, config.S3_PATH)

    df_transformed = transform_data(df)

    write_to_rds(df_transformed, config.RDS_CONFIG, config.TARGET_TABLE)

    spark.stop()

if __name__ == "__main__":
    main()