provider "aws" {
  region = "us-east-1" # change if needed
}

# S3 Buckets
resource "aws_s3_bucket" "bucket_a" {
  bucket = "source-bucket-exif-task"
  force_destroy = true
}

resource "aws_s3_bucket" "bucket_b" {
  bucket = "destination-bucket-exif-task"
  force_destroy = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_exif_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Lambda Function (EXIF remover)
resource "aws_lambda_function" "exif_lambda" {
  function_name = "remove_exif_metadata"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename      = "lambda.zip" # we will upload this

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.bucket_b.bucket
    }
  }
}

# S3 Event Notification (Trigger)
resource "aws_s3_bucket_notification" "bucket_a_notification" {
  bucket = aws_s3_bucket.bucket_a.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.exif_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_function.exif_lambda]
}

# IAM Permissions for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exif_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_a.arn
}

# IAM Users
resource "aws_iam_user" "user_a" {
  name = "UserA"
}

resource "aws_iam_user_policy" "user_a_policy" {
  name = "UserA-Policy"
  user = aws_iam_user.user_a.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.bucket_a.arn,
        "${aws_s3_bucket.bucket_a.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_user" "user_b" {
  name = "UserB"
}

resource "aws_iam_user_policy" "user_b_policy" {
  name = "UserB-Policy"
  user = aws_iam_user.user_b.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.bucket_b.arn,
        "${aws_s3_bucket.bucket_b.arn}/*"
      ]
    }]
  })
}
