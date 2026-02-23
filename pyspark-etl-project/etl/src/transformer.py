def transform_data(df):
    df_clean = df.dropDuplicates()

    df_clean = df_clean.fillna({
        "revenue": 0,
        "growth": 0
    })

    return df_clean