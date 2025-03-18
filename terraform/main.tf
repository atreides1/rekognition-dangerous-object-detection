# S3
resource "aws_s3_bucket" "detect_object_bucket" {
  bucket = var.bucket_name
  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# sns
resource "aws_sns_topic" "detect_object_topic" {
  name         = "detect-object-topic"
  display_name = "Security Alerts"
  tags = {
    "Project" = "RekognitionObjectDetection"
  }
}

resource "aws_sns_topic_subscription" "detect_object" {
  topic_arn = aws_sns_topic.detect_object_topic.arn
  protocol  = "email"
  endpoint  = var.email
}

# lambda

# setup for lambda: src files as zip, permissions policies, execution role
data "archive_file" "detect_object_lambda_payload" {
  type       = "zip"
  source_dir = "${path.module}/lambda-src"
  excludes = [
    "venv",
    "_pycache_"
  ]
  output_path = "${path.module}/payload.zip"
}

# create lambda execution role
resource "aws_iam_role" "detect_object_lambda_role" {
  name               = "detect_object_lambda_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  }
  EOF
  tags = {
    Project = "RekognitionObjectDetection"
  }
}
# permission policies
resource "aws_iam_policy" "detect_object_lambda_policy" {
  name        = "detect_object_lambda_policy"
  description = "Rekognition detect-labels, SNS publish, and S3 get-object"

  policy = <<EOT
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "WriteLogStreamsAndGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateLogGroup",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rekognition:DetectLabels"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "${aws_sns_topic.detect_object_topic.arn}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${aws_s3_bucket.detect_object_bucket.arn}/*"
        }
    ]
}
  EOT
  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# attach policy to iam role
resource "aws_iam_role_policy_attachment" "detect_object" {
  role       = aws_iam_role.detect_object_lambda_role.name
  policy_arn = aws_iam_policy.detect_object_lambda_policy.arn
}

# create the lambda function
resource "aws_lambda_function" "detect_object" {
  filename         = data.archive_file.detect_object_lambda_payload.output_path
  function_name    = "detect_object"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.detect_object_lambda_role.arn
  runtime          = "python3.13"
  source_code_hash = data.archive_file.detect_object_lambda_payload.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.detect_object_topic.arn
    }
  }
  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# s3-lambda trigger

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.detect_object.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.detect_object_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.detect_object_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.detect_object.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# kinesis video stream
resource "aws_kinesis_video_stream" "default" {
  name                    = "my-video-stream"
  data_retention_in_hours = 1

  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# rekognition
resource "aws_iam_role" "rekognition_role" {
  name               = "rekognition-stream-processor-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "rekognition.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# permission policies
resource "aws_iam_policy" "rekognition_policy" {
  name        = "rekognition_policy"
  description = "Kinesis get video stream, SNS publish, and S3 put-object permissions"

  policy = <<EOT
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "${aws_sns_topic.detect_object_topic.arn}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "${aws_s3_bucket.detect_object_bucket.arn}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:Get*",
                "kinesis:DescribeStreamSummary"
            ],
            "Resource": "${aws_kinesis_video_stream.default.arn}"
        }
    ]
}
  EOT
  tags = {
    Project = "RekognitionObjectDetection"
  }
}

# attach policy to iam role
resource "aws_iam_role_policy_attachment" "rekognition" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = aws_iam_policy.rekognition_policy.arn
}

resource "aws_rekognition_stream_processor" "detect-person" {
  role_arn = aws_iam_role.rekognition_role.arn
  name     = "my-stream-processor"

  data_sharing_preference {
    opt_in = false
  }

  output {
    s3_destination {
      bucket = aws_s3_bucket.detect_object_bucket.bucket
    }
  }

  settings {
    connected_home {
      labels = ["PERSON"]
    }
  }

  input {
    kinesis_video_stream {
      arn = aws_kinesis_video_stream.default.arn
    }
  }

  notification_channel {
    sns_topic_arn = aws_sns_topic.detect_object_topic.arn
  }
}