import json
import os
from decimal import Decimal

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.getenv("DYNAMODB_TABLE"))

# Convert Decimal in dynamoDB to type JSON supports
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            if o % 1 == 0:
                return int(o)
            else:
                return float(o)
        return super(DecimalEncoder, self).default(o)

def lambda_handler(event, context):
    # Scan the table to retrieve all items
    try:
        response = table.scan()
        items = response.get('Items', [])

        # Sort the items by timestamp in descending order
        sorted_items = sorted(items, key=lambda x: x['timestamp'], reverse=True)

        # Get the latest 10 items
        latest_ten_items = sorted_items[:30]

        # Return the items as a JSON object using the custom encoder
        return {
            'statusCode': 200,
            'body': json.dumps(latest_ten_items, cls=DecimalEncoder)
        }
    except Exception as e:
        # Handle any errors that occur during the scan
        return {
            'statusCode': 500,
            'body': json.dumps(str(e))
        }