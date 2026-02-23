S3_PATH = "s3a://your-bucket/input/inc5000.csv"

RDS_CONFIG = {
    "url": "jdbc:mysql://your-rds-endpoint:3306/etl_db",
    "user": "admin",
    "password": "password",
    "driver": "com.mysql.cj.jdbc.Driver"
}

TARGET_TABLE = "companies"