import boto3

dynamodb = boto3.client("dynamodb")
table_name = "example"

def lambda_handler(event, context):

    print("Received event: " + str(event))

    # print(dynamodb.scan(TableName=table_name))

    return {
        "statusCode": 200,
        "body": "Request Received!",
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    }
