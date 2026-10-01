import json

def lambda_handler(event, context):

    user = event["request"]["userAttributes"]["email"]

    print(f"New AcmeCloud user: {user}")

    return event