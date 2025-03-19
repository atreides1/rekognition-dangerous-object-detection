# Real-Time Dangerous Object Detection

## Background

Every second counts when a violent crime occurs and lives are in danger. Because of this, automated detection of dangerous objects such as guns and knives could save lives. This project focuses on AWS's Rekognition service for near real-time alerts when a dangerous object is detected in a video stream. 

## Usage
To use, deploy the infrastructure and set up the Kinesis Video Stream with your camera of choice. Start the Rekognition Stream Processor to begin person and object detection.

## Architecture

![Diagram](/images/architecture.png)

### Kinesis -> Rekognition
Kinesis Video Stream is used to provide streaming video to Rekognition. Using Rekognition's Streaming Video Events for connected home, an email alert is sent whenever a person is detected. The captured image frame is then sent to the associated S3 bucket and subsequently used for object detection.

### S3 -> Lambda <-> Rekognition -> SNS

Once a person has been detected, and the associated image frame sent to S3, a lambda function is used to access the image for further object detection. The image is processed by Rekognition's detect label API, and the results are then checked for flagged labels. If any such labels are detected, an email alert such as the one below is sent via SNS. A user or team can subscribe to the associated SNS topic to get the alerts.

![EmailScreenshot](/images/email_screenshot.jpg)

## Infrastructure as Code (IaC)
Originally, I had planned on using CloudFormation for IaC, but found limitations with creating s3-lambda triggers. Creating one requires it to be created during S3 bucket creation, which requires permissions to invoke the lambda function. The permissions require the S3 bucket ARN, resulting in a circular dependency. I used Terraform instead.

It may be possible to do the deployment using AWS SAM (Serverless Application Model), as the trigger is created as part of the lambda, so that's something to explore further.

### Terraform
This is the easier option for deployment; all the resources needed for the project are included. 

### CloudFormation
Files are included for creating the necessary resources, but the s3-lambda trigger must be created separately.

### Scripts
This includes Rekognition's stream processor creation and commands, as well as instructions and debugging tips for the Kinesis Video Stream setup.

## Misc. Considerations

The initial idea for this project was to check for an unauthorized person in a space, which raises the thorny question, 'Who is authorized, and who decides this?' In a small corporate setting, this question may not seem so complicated but can quickly spiral when applied to larger scenarios. Is a delivery person authorized to enter the building? What about visitors? 

If the list of authorized people is small enough, a dataset can be created such that the AI was trained to detect those people and send an alert otherwise. Simple enough.

However, if a general list is provided based on large datasets, Rekognition's results would most likely be biased. To make this more fair, I decided to check whenever *anyone* was present, and then search for dangerous objects present. This is still flawed, however. A toy gun is not a lethal weapon, yet would most likely be understood as such. I bring these flaws to light in order to demonstrate the various concerns and complexities that arise when using AI. 


