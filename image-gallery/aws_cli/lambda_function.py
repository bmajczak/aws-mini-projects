import json
import boto3

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Change bucket_name if you have changed the bucket name in setup.sh
    bucket_name = 'image-storage-6552'
    response = s3_client.list_objects_v2(Bucket=bucket_name)

    images = []
    if 'Contents' in response:
        for item in response['Contents']:
            # Exclude folders
            if not item['Key'].endswith('/'):
                image_url = f'https://{bucket_name}.s3.amazonaws.com/{item["Key"]}'
                images.append({"url": image_url})

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'images': images})
    }