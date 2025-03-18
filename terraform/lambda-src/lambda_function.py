import os
import json
import boto3
import urllib.parse

client = boto3.client('rekognition')
sns_client = boto3.client('sns')
sns_topic_arn = os.environ['SNS_TOPIC_ARN']

dangerous_labels = ["weapon", "gun", "knife"]

def lambda_handler(event, context):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_name = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    # send img to rekognition
    response = client.detect_labels(
        Image={
            'S3Object': {
                'Bucket': bucket_name,
                'Name': file_name,
            }
        },
        MaxLabels=10,
        MinConfidence=75
    )

    # check for flagged labels
    found_labels = []
    labels = response['Labels']
    msg = ""

    for label in labels:
        if label['Name'].lower() in dangerous_labels:
            found_labels.append(label['Name'])

    # generate msg text
    if len(found_labels) == 0:
        msg = "No dangerous objects detected"
    elif len(found_labels) == 1:
        msg = f"Dangerous object detected: {found_labels[0]}"
    else:
        msg = f"Dangerous objects detected: {', '.join(found_labels)}"

    # send alert to SNS
    if len(found_labels) > 0:
        sns_client.publish(
            TopicArn = sns_topic_arn,
            Message = msg,
            Subject = "Dangerous Object(s) Detected"
        )

    return {
        'statusCode': 200,
        'body': json.dumps(msg)
    }
