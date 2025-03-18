#! /usr/bin/env bash

aws rekognition create-stream-processor --name my-stream-processor\
    --input '{"KinesisVideoStream":{"Arn":"arn:aws:kinesisvideo:us-west-2:123456789012:stream/my-video-stream/1234567890123"}}'\
    --notification-channel SNSTopicArn=arn:aws:sns:us-west-2:123456789012:my-image-detection-topic\
    --stream-processor-output '{"S3Destination":{"Bucket":"my-image-detection-bucket"}}'\
    --role-arn arn:aws:iam::123456789012:role/rekognition-role\
    --tags Project=RekognitionObjectDetection\
    --settings '{"ConnectedHome":{"Labels":["PERSON"],"MinConfidence":75}}'

#  RESPONSE:
#  {
# 	 "StreamProcessorArn": "arn:aws:rekognition:us-west-2:123456789012:streamprocessor/my-stream-processor"
#  }

# The created stream processor should be on the following list:
# aws rekognition list-stream-processors