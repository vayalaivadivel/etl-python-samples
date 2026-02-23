def write_to_rds(df, config, table):
    df.write \
      .format("jdbc") \
      .option("url", config["url"]) \
      .option("dbtable", table) \
      .option("user", config["user"]) \
      .option("password", config["password"]) \
      .option("driver", config["driver"]) \
      .mode("append") \
      .save()