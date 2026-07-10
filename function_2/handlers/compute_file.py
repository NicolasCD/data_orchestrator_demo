import polars as pl

def handle(event, context):
    try:
        source = "s3://example-titanic/titanic.csv"
        df_dict = str(pl.read_csv(source).describe().to_dict())

    except Exception as e:
        return {
            "body": {
                "message": {repr(e)},
            },
            "statusCode": 400,
        }        
    return {
        "body": {
            "message": df_dict,
        },
        "statusCode": 200,
    }
