def lambda_handler(event, context):

    print("Received event: " + str(event))

    return {
        "statusCode": 200,
        "body": "Request Received!",
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    }
