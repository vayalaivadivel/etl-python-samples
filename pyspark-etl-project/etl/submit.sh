#!/bin/bash
# Navigate to project folder on EC2
cd ~/pyspark-etl-project/etl/src

# Spark submit with MySQL JDBC driver
spark-submit \
  --jars ~/pyspark-etl-project/etl/src/jars/mysql-connector-j-9.4.0.jar \
  load_s3_to_rds.py