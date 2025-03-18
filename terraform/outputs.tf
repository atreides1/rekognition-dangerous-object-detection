output "sns_topic_arn" {
  value       = aws_sns_topic.detect_object_topic.arn
  description = "the SNS topic ARN"
}

output "kinesis_video_stream_arn" {
  value       = aws_kinesis_video_stream.default.arn
  description = "the Kinesis Video Stream ARN"
}
