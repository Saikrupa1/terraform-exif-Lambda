import boto3
import os
from PIL import Image
from io import BytesIO

s3 = boto3.client('s3')
DEST_BUCKET = os.environ['DEST_BUCKET']

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        response = s3.get_object(Bucket=bucket, Key=key)
        img_data = response['Body'].read()
        
        img = Image.open(BytesIO(img_data))
        # Remove EXIF
        data = list(img.getdata())
        img_no_exif = Image.new(img.mode, img.size)
        img_no_exif.putdata(data)
        
        buffer = BytesIO()
        img_no_exif.save(buffer, format='JPEG')  # Save without EXIF
        buffer.seek(0)
        
        s3.put_object(Bucket=DEST_BUCKET, Key=key, Body=buffer.getvalue())
        
    return {"status": "success"}
