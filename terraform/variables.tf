variable "bucket_name" {
  type        = string
  description = "Name for the s3 bucket that stores image frames"
}

variable "email" {
  type        = string
  description = "A valid email address for the alerts to be sent to"
}

variable "region" {
  type        = string
  description = "A valid AWS region (eg us-east-1)"
}
