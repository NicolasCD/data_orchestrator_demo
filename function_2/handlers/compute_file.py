import polars as pl
import json

def handle(event, context):
    try:
        source = "s3://example-titanic/titanic.csv"
        parsed = json.loads(pl.read_csv(source).describe().write_json())

    except Exception as e:
        return {
            "body": {
                "message": {repr(e)},
            },
            "statusCode": 400,
        }        
    return {
        "body": {
            "message": json.dumps(parsed, indent=4),
        },
        "statusCode": 200,
    }
